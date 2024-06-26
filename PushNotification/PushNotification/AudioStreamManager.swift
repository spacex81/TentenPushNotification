import PushToTalk
import AVFoundation
import LiveKit
import UIKit

class AudioStreamManager: NSObject, PTChannelManagerDelegate, PTChannelRestorationDelegate {
    static let shared = AudioStreamManager()
    private var channelManager: PTChannelManager?
    
    private override init() {
        super.init()
        setupChannelManager()
    }
    
    private func setupChannelManager() {
        Task {
            do {
                self.channelManager = try await PTChannelManager.channelManager(delegate: self, restorationDelegate: self)
            } catch {
                print("Failed to create channelManager: \(error)")
            }
        }
    }
    
    func joinChannel(channelUUID: UUID, livekitToken: String) {
        print("AudioStreamManager-joinChannel")
        guard let channelManager = channelManager else { return }
        let channelImage = UIImage(named: "ChannelImage")
        let channelDescriptor = PTChannelDescriptor(name: "The channel name", image: channelImage)
        
        // connect to livekit using 'livekitToken'
        print("Connecting to Livekit with token: \(livekitToken)")
        channelManager.requestJoinChannel(channelUUID: channelUUID, descriptor: channelDescriptor)
    }
    
    // PTChannelManagerDelegate method
    func channelManager(_ channelManager: PTChannelManager, didJoinChannel channelUUID: UUID, reason: PTChannelJoinReason) {
        print("1-channelManager-didJoinChannel")
    }
    
    func channelManager(_ channelManager: PTChannelManager, receivedEphemeralPushToken pushToken: Data) {
        print("2-channelManager-receivedEphemeralPushToken")
    }

    func channelManager(_ channelManager: PTChannelManager, channelUUID: UUID, didBeginTransmittingFrom source: PTChannelTransmitRequestSource) {
        print("3-channelManager-didBeginTransmittingFrom")
    }
    
    func channelManager(_ channelManager: PTChannelManager, channelUUID: UUID, didEndTransmittingFrom source: PTChannelTransmitRequestSource) {
        print("4-channelManager-didEndTransmittingFrom")
    }
    
    func channelManager(_ channelManager: PTChannelManager, didLeaveChannel channelUUID: UUID, reason: PTChannelLeaveReason) {
        print("5-channelManager-didLeaveChannel")
    }

    func incomingPushResult(channelManager: PTChannelManager, channelUUID: UUID, pushPayload: [String : Any]) -> PTPushResult {
       // Default implementation to pass the build
       print("Incoming push result for channel: \(channelUUID)")
       return PTPushResult.leaveChannel
    }
   
    func channelManager(_ channelManager: PTChannelManager, didActivate audioSession: AVAudioSession) {
       // Default implementation to pass the build
       print("Activated audio session")
    }
   
    func channelManager(_ channelManager: PTChannelManager, didDeactivate audioSession: AVAudioSession) {
       // Default implementation to pass the build
       print("Deactivated audio session")
    }
   
    // PTChannelRestorationDelegate method
    func channelDescriptor(restoredChannelUUID channelUUID: UUID) -> PTChannelDescriptor {
       // Default implementation to pass the build
       let channelImage = UIImage(named: "profile_0")
       return PTChannelDescriptor(name: "Restored Channel", image: channelImage)
    }

}


//extension AudioStreamManager: RoomDelegate {
//    func room(_ room: Room, didUpdateSpeakingParticipants speakers: [Participant]) {
//        // Handle updates to the speakers in the LiveKit room
//    }
//    
//    func room(_ room: Room, participant: Participant, didUpdate track: Track, muted: Bool) {
//        // Handle updates to the participant's track
//    }
//    
//    func room(_ room: Room, participant: Participant, didUpdateConnectionQuality connectionQuality: ConnectionQuality) {
//        // Handle updates to the participant's connection quality
//    }
//    
//    func room(_ room: Room, participant: Participant, didUpdateMetadata metadata: String?) {
//        // Handle updates to the participant's metadata
//    }
//    
//    func room(_ room: Room, didUpdate connectionState: ConnectionState) {
//        // Handle updates to the room's connection state
//    }
//}
