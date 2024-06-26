import SwiftUI
import SDWebImageSwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ShowAddViewButton: View {
    @Binding var showAddView: Bool
    var circleSize: CGFloat = 100

    var body: some View {
        Button {
            showAddView.toggle()
        } label: {
            Image(systemName: "plus")
                .font(.largeTitle).bold()
                .frame(width: circleSize, height: circleSize)
                .background(Circle().stroke(Color.gray, lineWidth: 2))
        }
        .onChange(of: showAddView) { oldValue, newValue in
            if newValue {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            }
        }
    }
}

struct FriendsScrollView: View {
    @Binding var showAddView: Bool
    @Binding var selectedProfileImageUrl: String?
    @Binding var lastSnappedIndex: Int?
    @StateObject var friendViewModel: FriendViewModel
    let circleSize: CGFloat
    let cameraStrokeSize: CGFloat
    
    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 23) {
                    GeometryReader { geometry in
                        let midX = geometry.frame(in: .global).midX
                        let screenWidth = UIScreen.main.bounds.width
                        let scale = calculateScale(midX: midX, screenWidth: screenWidth)
                        
                        ShowAddViewButton(showAddView: $showAddView, circleSize: circleSize)
                            .scaleEffect(scale)
                            .frame(width: circleSize, height: circleSize)
                    }
                    .frame(width: circleSize, height: circleSize)
                    .id("showAddViewButton")
                    
                    ForEach(Array(friendViewModel.friends.enumerated()), id: \.element.id) { index, friend in
                        GeometryReader { geometry in
                            let midX = geometry.frame(in: .global).midX
                            let screenWidth = UIScreen.main.bounds.width
                            let scale = calculateScale(midX: midX, screenWidth: screenWidth)
                            
                            if let profileImageUrl = friend.profileImageUrl, let url = URL(string: profileImageUrl) {
                                WebImage(url: url)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: circleSize, height: circleSize)
                                    .clipShape(Circle())
                                    .scaleEffect(scale)
                                    .onChange(of: geometry.frame(in: .global).midX) { newValue, oldValue in
                                        let screenMidX = UIScreen.main.bounds.width / 2
                                        if abs(newValue - screenMidX) < 50 {
                                            if lastSnappedIndex != index {
                                                lastSnappedIndex = index
                                                selectedProfileImageUrl = profileImageUrl
                                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                                generator.impactOccurred()
                                            }
                                        }
                                    }
                            } else {
                                Image("profile_\(index + 2)")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: circleSize, height: circleSize)
                                    .clipShape(Circle())
                                    .scaleEffect(scale)
                                    .onChange(of: geometry.frame(in: .global).midX) { newValue, oldValue in
                                        let screenMidX = UIScreen.main.bounds.width / 2
                                        if abs(newValue - screenMidX) < 70 {
                                            if lastSnappedIndex != index {
                                                lastSnappedIndex = index
                                                selectedProfileImageUrl = nil
                                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                                generator.impactOccurred()
                                            }
                                        }
                                    }
                            }
                        }
                        .frame(width: circleSize, height: circleSize)
                        .id(friend.id)
                    }
                    
                    GeometryReader { geometry in
                        let midX = geometry.frame(in: .global).midX
                        let screenWidth = UIScreen.main.bounds.width
                        let scale = calculateScale(midX: midX, screenWidth: screenWidth)
                        
                        ShowAddViewButton(showAddView: $showAddView, circleSize: circleSize)
                            .scaleEffect(scale)
                            .frame(width: circleSize, height: circleSize)
                    }
                    .frame(width: circleSize, height: circleSize)
                }
                .scrollTargetLayout()
                .padding(.horizontal, (UIScreen.main.bounds.width - circleSize) / 2)
            }
            .scrollTargetBehavior(.viewAligned)
            .onReceive(friendViewModel.$friends) { friends in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if let firstFriend = friends.first {
                        scrollProxy.scrollTo(firstFriend.id, anchor: UnitPoint(x: 0.43, y: 0.5))

                        if let profileImageUrl = firstFriend.profileImageUrl {
                            selectedProfileImageUrl = profileImageUrl
                        } else {
                            selectedProfileImageUrl = nil
                        }
                    }
                }
            }
        }
    }

    private func calculateScale(midX: CGFloat, screenWidth: CGFloat) -> CGFloat {
        let center = screenWidth / 2
        let distance = abs(midX - center)
        let maxDistance = screenWidth / 2
        let threshold: CGFloat = 150
        let factor: CGFloat = 0.3
        
        if distance < threshold {
            return 1.0
        } else {
            let adjustedDistance = distance - threshold
            let adjustedMaxDistance = maxDistance - threshold
            return max(0.5, 1 - (adjustedDistance / adjustedMaxDistance) * factor)
        }
    }
}

struct HomeView: View {
    @Binding var isUserLoggedIn: Bool
    @State private var showAddView = false
    @State private var profileImageUrl: String?
    @State private var pin: String?
    @State private var selectedProfileImageUrl: String?
    @State private var lastSnappedIndex: Int? 
    @StateObject private var friendViewModel = FriendViewModel()
    
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
                friendViewModel.fetchFriends()
            }
            .onReceive(friendViewModel.$friends) { friends in
                if let firstFriend = friends.first, let profileImageUrl = firstFriend.profileImageUrl {
                    self.selectedProfileImageUrl = profileImageUrl
                }
            }
            .onChange(of: lastSnappedIndex) { oldValue, newValue in
                print("lastSnappedIndex changed to : \(String(describing: lastSnappedIndex))")
                if lastSnappedIndex != nil {
                    let receiverFcmToken = friendViewModel.friends[lastSnappedIndex!].fcmToken
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
