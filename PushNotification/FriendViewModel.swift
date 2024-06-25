import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import SDWebImageSwiftUI

class FriendViewModel: ObservableObject {
    @Published var friends: [FriendModel] = []
    
    private var db = Firestore.firestore()
    
    init() {}
    
    init(sampleData: Bool) {
        if sampleData {
            self.friends = [
                FriendModel(uid: "1", username: "John Doe", profileImageUrl: ""),
                FriendModel(uid: "2", username: "Jane Smith", profileImageUrl: ""),
                FriendModel(uid: "3", username: "Alice Johnson", profileImageUrl: ""),
                FriendModel(uid: "4", username: "John Doe2", profileImageUrl: ""),
                FriendModel(uid: "5", username: "Jane Smith2", profileImageUrl: ""),
                FriendModel(uid: "6", username: "Alice Johnson2", profileImageUrl: "")
            ]
        }
    }
    
    func fetchFriends() {
        guard let userUID = Auth.auth().currentUser?.uid else {
            print("No user is currently signed in.")
            return
        }
        
        db.collection("users").document(userUID).addSnapshotListener { documentSnapshot, error in
            if let error = error {
                print("Error fetching user document: \(error)")
                return
            }
            
            guard let document = documentSnapshot, document.exists else {
                print("User document does not exist")
                return
            }
            
            do {
                let userModel = try document.data(as: UserModel.self)

                self.friends = userModel.friends
            } catch let error {
                print("Error decoding user model: \(error)")
            }
        }
    }
}
