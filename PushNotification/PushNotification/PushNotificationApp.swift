import SwiftUI
import FirebaseCore
import FirebaseMessaging
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // Register for remote notifications
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            } else {
                print("Authorization failed: \(String(describing: error?.localizedDescription))")
            }
        }

        Messaging.messaging().delegate = self
        
        return true
    }
    
    private func handlePushNotification(userInfo: [AnyHashable: Any]) {
        print("Push Notification received!")
        print(userInfo)

        if let ephemeralPushToken = userInfo["ephemeralPushToken"] as? String {
            print("Received ephemeral push token: \(ephemeralPushToken)")
            handleEphemeralPushToken(ephemeralPushToken)
        } else if let channelUUIDString = userInfo["channelUUID"] as? String,
                  let channelUUID = UUID(uuidString: channelUUIDString),
                  let livekitToken = userInfo["livekitToken"] as? String,
                  let senderFcmToken = userInfo["senderFcmToken"] as? String,
                  let receiverFcmToken = userInfo["receiverFcmToken"] as? String {
            print("Received channel information: channelUUID = \(channelUUID), livekitToken = \(livekitToken)")
            DispatchQueue.main.async {
                AudioStreamManager.shared.joinChannel(channelUUID: channelUUID, livekitToken: livekitToken, senderFcmToken: senderFcmToken, receiverFcmToken: receiverFcmToken)
                self.presentWalkieTalkieUI()
            }
        } else {
            print("Unknown notification type")
        }
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

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        print("APNs token received: \(deviceToken.map { String(format: "%02x", $0) }.joined())")
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")
        let dataDict: [String: String] = ["token": fcmToken ?? ""]
        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        let userInfo = notification.request.content.userInfo
        handlePushNotification(userInfo: userInfo)

        if #available(iOS 14.0, *) {
            completionHandler([.banner, .badge, .sound])
        } else {
            completionHandler([.alert, .badge, .sound])
        }
    }
    
    private func handleEphemeralPushToken(_ ephemeralPushToken: String) {
        print("Handling ephemeral push token: \(ephemeralPushToken)")
        // Example action: AudioStreamManager.shared.useEphemeralPushToken(ephemeralPushToken)
    }
}

@main
struct PushNotificationApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

