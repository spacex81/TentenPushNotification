import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import FirebaseMessaging

struct AuthView: View {
    @Binding var isUserLoggedIn: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var isLoginMode = true
    @State private var errorMessage = ""
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var fcmToken: String?
    
    var body: some View {
        VStack {
            Picker(selection: $isLoginMode, label: Text("Login or Register")) {
                Text("Login").tag(true)
                Text("Register").tag(false)
            }.pickerStyle(SegmentedPickerStyle())
            
            if !isLoginMode {
                Button(action: {
                    showImagePicker.toggle()
                }) {
                    if let selectedImage = selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
            }
            
            TextField("Email", text: $email)
                .autocapitalization(.none)
                .padding()
                .background(Color(.secondarySystemBackground))
            
            SecureField("Password", text: $password)
                .padding()
                .background(Color(.secondarySystemBackground))
            
            Button(action: handleAuthentication) {
                Text(isLoginMode ? "Login" : "Register")
                    .foregroundColor(.white)
                    .padding()
                    .background(.blue)
                    .cornerRadius(8)
            }
            
            Text(errorMessage)
                .foregroundColor(.red)
                .padding()
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .onAppear {
            self.fetchFCMToken()
        }
    }
    
    private func fetchFCMToken() {
        // retrieve currentUser's fcmToken
        Messaging.messaging().token { token, error in
            if let error = error {
                print("Error fetching FCM token: \(error)")
            } else if let token = token {
                self.fcmToken = token
                print("FCM token: \(token)")
            }
        }
    }
    
    private func handleAuthentication() {
        if isLoginMode {
            loginUser()
        } else {
            registerUser()
        }
    }
    
    private func loginUser() {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
                return
            }
            isUserLoggedIn = true
        }
    }
    
    private func registerUser() {
        guard let imageData = selectedImage?.jpegData(compressionQuality: 0.8) else {
            errorMessage = "Please select a profile image."
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
                return
            }
            guard let uid = result?.user.uid else { return }
            
            let storageRef = Storage.storage().reference().child("profile_images").child("\(uid).jpg")
            storageRef.putData(imageData, metadata: nil) { metadata, error in
                if let error = error {
                    errorMessage = error.localizedDescription
                    return
                }
                
                storageRef.downloadURL { url, error in
                    if let error = error {
                        errorMessage = error.localizedDescription
                        return
                    }
                    
                    guard let profileImageUrl = url?.absoluteString else { return }
                    
                    let userModel = UserModel(
                        uid: uid,
                        email: email,
                        fcmToken: self.fcmToken,
                        username: email.split(separator: "@").first.map(String.init) ?? "User",
                        pin: UserModel.generatePin(),
                        profileImageUrl: profileImageUrl,
                        friends: []
                    )
                    
                    let db = Firestore.firestore()
                    do {
                        try db.collection("users").document(uid).setData(from: userModel)
                        isUserLoggedIn = true
                    } catch let error {
                        errorMessage = "Error saving user data: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            picker.dismiss(animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

#Preview {
    AuthView(isUserLoggedIn: .constant(true))
}
