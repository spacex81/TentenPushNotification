import Foundation

struct FriendModel: Codable, Identifiable, Equatable {
    var id: String { uid }
    var uid: String
    var fcmToken: String?
    var username: String
    var profileImageUrl: String?
    
    init(uid: String, fcmToken: String? = nil, username: String, profileImageUrl: String? = nil) {
        self.uid = uid
        self.fcmToken = fcmToken
        self.username = username
        self.profileImageUrl = profileImageUrl
    }
}
