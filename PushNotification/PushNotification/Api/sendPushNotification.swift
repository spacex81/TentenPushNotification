import Foundation
import SwiftUI
import UIKit

func sendPushNotification(from senderFcmToken: String, to receiverFcmToken: String, senderUid: String, receiverUid: String) {
    guard let url = URL(string: "https://us-central1-tentenios.cloudfunctions.net/sendPushNotification") else {
        print("Invalid URL")
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let body: [String: Any] = [
        "senderFcmToken": senderFcmToken,
        "receiverFcmToken": receiverFcmToken,
        "senderUid": senderUid,
        "receiverUid": receiverUid
    ]
    
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: .fragmentsAllowed)
    } catch {
        print("Failed to serialize JSON: ", error)
        return
    }
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Error sending push notification: ", error)
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("Invalid response received from the server")
            return
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            print("Server error: ", httpResponse.statusCode)
            return
        }
        
        guard let data = data else {
            print("No data received from the server")
            return
        }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                if let message = json["message"] as? String {
                    print("Response message: ", message)
                }
                
                if let senderLivekitToken = json["senderLivekitToken"] as? String,
                   let channelUUIDString = json["channelUUID"] as? String,
                   let channelUUID = UUID(uuidString: channelUUIDString) {
                    DispatchQueue.main.async {
                        AudioStreamManager.shared.joinChannel(
                            channelUUID: channelUUID,
                            livekitToken: senderLivekitToken,
                            senderFcmToken: senderFcmToken,
                            receiverFcmToken: receiverFcmToken
                        )
                        presentWalkieTalkieUI()
                    }
                }
            } else {
                print("Invalid JSON received from the server")
            }
        } catch {
            print("Failed to parse JSON: ", error)
        }
    }
    
    task.resume()
}

private func presentWalkieTalkieUI() {
    guard let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
          let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
        print("No active window scene found")
        return
    }
    
    let walkieTalkieView = WalkieTalkieView()
    let hostingController = UIHostingController(rootView: walkieTalkieView)
    
    if let rootViewController = window.rootViewController {
        if let presentedViewController = rootViewController.presentedViewController {
            presentedViewController.present(hostingController, animated: true)
        } else {
            rootViewController.present(hostingController, animated: true)
        }
    } else {
        print("No root view controller found")
    }
}
