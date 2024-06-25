import Foundation

struct UserModel: Codable {
    var uid: String
    var email: String
    var fcmToken: String?
    var username: String
    var pin: String
    var profileImageUrl: String?
    var friends: [FriendModel]
    
    init(uid: String, email: String, fcmToken: String? = nil, username: String, pin: String, profileImageUrl: String? = nil, friends: [FriendModel] = []) {
        self.uid = uid
        self.email = email
        self.fcmToken = fcmToken
        self.username = username
        self.pin = pin
        self.profileImageUrl = profileImageUrl
        self.friends = friends
    }
    
    static func generatePin() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyz0123456789"
        return String((0..<7).map { _ in letters.randomElement()! })
    }
}

