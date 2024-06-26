import SwiftUI
import SDWebImageSwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine

struct HomeView: View {
    @Binding var isUserLoggedIn: Bool
    @State private var showAddView = false
    @State private var profileImageUrl: String?
    @State private var pin: String?
    @State private var selectedProfileImageUrl: String?
    @State private var lastSnappedIndex: Int? 
    @State private var receiverFcmToken: String?
    @StateObject private var friendViewModel = FriendViewModel()
    private var cancellables = Set<AnyCancellable>()

    
    let cameraStrokeSize = 120.0
    
    init(isUserLoggedIn: Binding<Bool>, friendViewModel: FriendViewModel = FriendViewModel()) {
        self._isUserLoggedIn = isUserLoggedIn
        self._friendViewModel = StateObject(wrappedValue: friendViewModel)
    }
    
    var body: some View {
        let circleSize = cameraStrokeSize * 0.80

        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    if let url = selectedProfileImageUrl, let imageUrl = URL(string: url) {
                        WebImage(url: imageUrl)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                    } else {
//                        Image(systemName: "person.crop.circle")
//                            .resizable()
//                            .aspectRatio(contentMode: .fill)
//                            .frame(width: geometry.size.width, height: geometry.size.height)
                    }
                    VStack {
                        Spacer()
                        ZStack {
                            FriendsScrollView(
                                showAddView: $showAddView,
                                selectedProfileImageUrl: $selectedProfileImageUrl,
                                lastSnappedIndex: $lastSnappedIndex,
                                receiverFcmToken: $receiverFcmToken,
                                friendViewModel: friendViewModel,
                                circleSize: circleSize,
                                cameraStrokeSize: cameraStrokeSize
                            )
                            
                            Circle()
                                .stroke(.white, lineWidth: 10)
                                .frame(width: cameraStrokeSize, height: cameraStrokeSize)
                        }
                        .padding(.bottom, 10)
                    }
                }
            }
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                fetchUserData()
                friendViewModel.fetchFriends() {
                    if friendViewModel.friends.count > 0 {
                        lastSnappedIndex = 0
                        receiverFcmToken = friendViewModel.friends[0].fcmToken
                        print("initial lastSnappedIndex: \(String(describing: lastSnappedIndex))")
                        print("initial receiverFcmToken: \(String(describing: receiverFcmToken))")
                    }
                }
            }
            .onReceive(friendViewModel.$friends) { friends in
                if let firstFriend = friends.first, let profileImageUrl = firstFriend.profileImageUrl {
                    self.selectedProfileImageUrl = profileImageUrl
                }
            }
            .onChange(of: lastSnappedIndex) { oldValue, newValue in
                print("lastSnappedIndex changed to : \(String(describing: lastSnappedIndex))")
                if lastSnappedIndex != nil {
                    receiverFcmToken = friendViewModel.friends[lastSnappedIndex!].fcmToken
                    print("receiverFcmToken: \(String(describing: receiverFcmToken))")
                } else {
                    print("lastSnappedIndex is nil")
                }
            }
        }
        .sheet(isPresented: $showAddView) {
            AddView(profileImageUrl: profileImageUrl, pin: pin, isUserLoggedIn: $isUserLoggedIn)
        }
    }
    
    private func fetchUserData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { document, error in
            if let document = document, document.exists {
                if let profileImageUrl = document.data()?["profileImageUrl"] as? String {
                    self.profileImageUrl = profileImageUrl
                }
                if let pin = document.data()?["pin"] as? String {
                    self.pin = pin
                }
            } else {
                print("Document does not exist")
            }
        }
    }
    
    private func signOut() {
        do {
            try Auth.auth().signOut()
            isUserLoggedIn = false
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
}


#Preview {
    HomeView(isUserLoggedIn: .constant(true), friendViewModel: FriendViewModel(sampleData: true))
        .preferredColorScheme(.dark)
}
