import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct PinView: View {
    var myPin: String?
    
    @State private var pin = ""
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(.black).ignoresSafeArea()
                VStack {
                    Text("add by #pin")
                        .foregroundColor(.white)
                        .font(.largeTitle)
                    Text("ask your friend for their pin")
                        .foregroundColor(.gray)
                        .font(.title2)
                    TextField("#", text: $pin)
                        .autocapitalization(.none)
                        .padding()
                        .frame(width: geometry.size.width * 0.8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(UIColor.systemGray2))
                        )
                    PinButton(pin: myPin ?? "myPin is empty", isShimmering: false)
                    HStack {
                        Spacer()
                        Button {
                            addFriendWithPin()
                        } label: {
                            Image(systemName: "arrow.right")
                                .font(.largeTitle)
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
    
    private func addFriendWithPin() {
        print("addFriendWithPin Start!")
        guard let currentUser = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        
        // Query the users collection to find a user with the entered pin
        db.collection("users").whereField("pin", isEqualTo: pin).getDocuments { querySnapshot, error in
            if let error = error {
                print("Error finding user with pin: \(error)")
                return
            }
            
            guard let documents = querySnapshot?.documents, !documents.isEmpty else {
                print("No user found with the entered pin.")
                return
            }
            print("Found a friend that corresponds to the pin: \(pin)!")
            
            // Assuming the pin is unique and only one document will be returned
            let document = documents.first!
            let data = document.data()
            
            let friendUid = data["uid"] as? String ?? ""
            let friendFcmToken = data["fcmToken"] as? String ?? ""
            let friendUsername = data["username"] as? String ?? ""
            let friendProfileImageUrl = data["profileImageUrl"] as? String ?? ""
            
            print("Creating new instance of FriendModel")
            let newFriend = FriendModel(
                uid: friendUid,
                fcmToken: friendFcmToken,
                username: friendUsername,
                profileImageUrl: friendProfileImageUrl
            )
            
            print("Adding new FriendModel instance to 'friends' category")
            // Add the new friend to the current user's friends list
            let userRef = db.collection("users").document(currentUser.uid)
            userRef.updateData([
                "friends": FieldValue.arrayUnion([try! Firestore.Encoder().encode(newFriend)])
            ]) { error in
                if let error = error {
                    print("Error adding friend: \(error)")
                } else {
                    print("Friend added successfully!")
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        print("addFriendWithPin Finish!")
    }
}

#Preview {
    PinView()
}
