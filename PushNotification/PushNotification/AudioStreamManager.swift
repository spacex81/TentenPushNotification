import PushToTalk
import AVFoundation
import LiveKit
import UIKit

class AudioStreamManager: NSObject, PTChannelManagerDelegate, PTChannelRestorationDelegate, RoomDelegate {

    static let shared = AudioStreamManager()
    private var channelManager: PTChannelManager?
    private var senderFcmToken: String?
    private var receiverFcmToken: String?
    private var currentChannelUUID: UUID?
    private var room: Room?
    private let livekitUrl = "wss://tentwenty-bp8gb2jg.livekit.cloud"
    
    private var isChannelManagerInitialized = false
    private var joinChannelQueue: [(UUID, String, String, String)] = []
    
    private override init() {
        super.init()
        setupChannelManager()
    }
    
    private func setupChannelManager() {
        Task {
            do {
                let channelManager = try await PTChannelManager.channelManager(delegate: self, restorationDelegate: self)
                self.channelManager = channelManager
                self.isChannelManagerInitialized = true
                print("ChannelManager successfully created")
                processJoinChannelQueue()
            } catch {
                print("Failed to create channelManager: \(error)")
            }
        }
    }
    
    private func processJoinChannelQueue() {
        for (channelUUID, livekitToken, senderFcmToken, receiverFcmToken) in joinChannelQueue {
            performJoinChannel(channelUUID: channelUUID, livekitToken: livekitToken, senderFcmToken: senderFcmToken, receiverFcmToken: receiverFcmToken)
        }
        joinChannelQueue.removeAll()
    }
    
    func joinChannel(channelUUID: UUID, livekitToken: String, senderFcmToken: String, receiverFcmToken: String) {
        print("AudioStreamManager-joinChannel")
        
        if isChannelManagerInitialized {
            performJoinChannel(channelUUID: channelUUID, livekitToken: livekitToken, senderFcmToken: senderFcmToken, receiverFcmToken: receiverFcmToken)
        } else {
            print("Channel Manager is not initialized, queuing join channel request...")
            joinChannelQueue.append((channelUUID, livekitToken, senderFcmToken, receiverFcmToken))
        }
    }
    
    private func performJoinChannel(channelUUID: UUID, livekitToken: String, senderFcmToken: String, receiverFcmToken: String) {
        guard let channelManager = channelManager else {
            print("channel manager is not initialized, cannot join channel")
            return
        }
        
        let channelImage = UIImage(named: "profile_0")
        let channelDescriptor = PTChannelDescriptor(name: "The channel name", image: channelImage)
        
        self.senderFcmToken = senderFcmToken
        self.receiverFcmToken = receiverFcmToken
        self.currentChannelUUID = channelUUID
        
        print("Connecting to Livekit with token: \(livekitToken)")
        joinRoom(token: livekitToken)
        
        print("Requesting to join channel with UUID: \(channelUUID)")
        channelManager.requestJoinChannel(channelUUID: channelUUID, descriptor: channelDescriptor)
    }
    
    private func joinRoom(token: String) {
        Task {
            let room = Room(delegate: self)
            do {
                try await room.connect(url: livekitUrl, token: token)
                print("Connected to LiveKit Room")
                self.room = room
            } catch {
                print("Failed to connect to LiveKit room: \(error)")
            }
        }
    }
    
    // PTChannelManagerDelegate methods
    func channelManager(_ channelManager: PTChannelManager, didJoinChannel channelUUID: UUID, reason: PTChannelJoinReason) {
        print("1-channelManager-didJoinChannel")
    }
    
    func channelManager(_ channelManager: PTChannelManager, failedToJoinChannel channelUUID: UUID, error: any Error) {
        print("1-1-channelManager-failedToJoinChannel: \(error)")
    }
    
    func channelManager(_ channelManager: PTChannelManager, receivedEphemeralPushToken pushToken: Data) {
        print("2-channelManager-receivedEphemeralPushToken")
        
        // by commenting this code, the walkie talkie feature finally works
        
//        guard let senderFcmToken = senderFcmToken, let receiverFcmToken = receiverFcmToken, let currentChannelUUID = currentChannelUUID else {
//            print("Sender FCM token or Receiver FCM token or channelUUID is not available")
//            return
//        }
//        
//        let tokenString = pushToken.map { String(format: "%02x", $0) }.joined()
//        print("Ephemeral Push Token: \(tokenString)")
//        sendEphemeralPushTokenToServer(pushToken: tokenString, senderFcmToken: senderFcmToken, receiverFcmToken: receiverFcmToken, channelUUID: currentChannelUUID)
    }
    
    private func sendEphemeralPushTokenToServer(pushToken: String, senderFcmToken: String, receiverFcmToken: String, channelUUID: UUID) {
        guard let url = URL(string: "https://us-central1-tentenios.cloudfunctions.net/handleEphemeralPushToken") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["ephemeralPushToken": pushToken, "senderFcmToken": senderFcmToken, "receiverFcmToken": receiverFcmToken, "channelUUID": channelUUID.uuidString, "message": "PTT notification message"]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Failed to send ephemeral push token: \(error)")
                return
            }
            print("Successfully sent ephemeral push token to server")
        }
        task.resume()
    }

    func startTransmittingAudio() {
        print("startTransmittingAudio")
        guard let channelManager = channelManager, let channelUUID = currentChannelUUID else {
            print("Channel Manager or Channel UUID is not available")
            return
        }
        
        channelManager.requestBeginTransmitting(channelUUID: channelUUID)
    }
    
    func stopTransmittingAudio() {
        print("stopTransmittingAudio")
        guard let room = room else {
            print("Room is not connected")
            return
        }
        
        Task {
            await room.localParticipant.unpublishAll()
            print("room.localParticipant.unpublishAll Success")
        }
        
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
    }
    
    func channelManager(_ channelManager: PTChannelManager, channelUUID: UUID, didBeginTransmittingFrom source: PTChannelTransmitRequestSource) {
        print("3-channelManager-didBeginTransmittingFrom")
        guard let room = room else {
            print("Room is not connected")
            return
        }

        let audioSession = AVAudioSession.sharedInstance()
        do {
            if audioSession.isOtherAudioPlaying {
                print("Other audio is playing, stopping it before activating the session")
                try audioSession.setActive(false)
            }

            print("Setting audio session category, mode, and activating")
            try audioSession.setCategory(.playAndRecord, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setMode(.default)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            print("Audio session configured and activated successfully")
        } catch {
            print("Failed to configure and activate audio session: \(error)")
            return
        }

        let localAudioTrack: LocalAudioTrack = LocalAudioTrack.createTrack()
        Task {
            do {
                try await room.localParticipant.publish(audioTrack: localAudioTrack)
                print("room.localParticipant.publish Success")
            } catch {
                print("Failed to Publish Local Audio Track: \(error)")
            }
        }
    }
    
    func channelManager(_ channelManager: PTChannelManager, channelUUID: UUID, didEndTransmittingFrom source: PTChannelTransmitRequestSource) {
        print("4-channelManager-didEndTransmittingFrom")
        stopTransmittingAudio()
    }
    
    
    func channelManager(_ channelManager: PTChannelManager, didLeaveChannel channelUUID: UUID, reason: PTChannelLeaveReason) {
        print("5-channelManager-didLeaveChannel")
        disconnectRoom()
    }
    
    private func disconnectRoom() {
        Task {
            await room?.disconnect()
            print("Disconnected from LiveKit Room")
            self.room = nil
        }
    }
    
    func channelManager(_ channelManager: PTChannelManager, didActivate audioSession: AVAudioSession) {
        print("channelManager-didActivate")
    }
    
    func channelManager(_ channelManager: PTChannelManager, didDeactivate audioSession: AVAudioSession) {
        print("channelManager-didDeactivate")
    }

    func incomingPushResult(channelManager: PTChannelManager, channelUUID: UUID, pushPayload: [String: Any]) -> PTPushResult {
        print("incomingPushResult-PTT Notification received.")
        return PTPushResult.leaveChannel
    }
    
    func channelDescriptor(restoredChannelUUID channelUUID: UUID) -> PTChannelDescriptor {
        let channelImage = UIImage(named: "profile_0")
        return PTChannelDescriptor(name: "Restored Channel", image: channelImage)
    }
    
    func room(_ room: Room, participantDidConnect participant: RemoteParticipant) {
        print("Remote Participant is connected")
    }
    
    func room(_ room: Room, participant: RemoteParticipant, didPublishTrack publication: RemoteTrackPublication) {
        Task {
            try await publication.track?.start()
        }
    }
}
