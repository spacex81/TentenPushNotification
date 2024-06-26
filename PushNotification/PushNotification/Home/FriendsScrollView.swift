import SwiftUI
import SDWebImageSwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine

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
    @Binding var receiverFcmToken: String?
    @Binding var senderUid: String?
    @State private var receiverUid: String?
    
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
                                                receiverUid = friend.uid
                                                
                                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                                generator.impactOccurred()
                                            }
                                        }
                                    }
                                    .onTapGesture {
                                        if let token = receiverFcmToken {
                                            sendPushNotification(to: token, senderUid: senderUid ?? "", receiverUid: receiverUid ?? "")
                                        } else {
                                            print("No FCM token available")
                                        }
                                    }
                            } else {
//                                Image("profile_\(index + 2)") // these chunk is for preview. We will delte this else part 
//                                    .resizable()
//                                    .scaledToFill()
//                                    .frame(width: circleSize, height: circleSize)
//                                    .clipShape(Circle())
//                                    .scaleEffect(scale)
//                                    .onChange(of: geometry.frame(in: .global).midX) { newValue, oldValue in
//                                        let screenMidX = UIScreen.main.bounds.width / 2
//                                        if abs(newValue - screenMidX) < 70 {
//                                            if lastSnappedIndex != index {
//                                                lastSnappedIndex = index
//                                                selectedProfileImageUrl = nil
//                                                let generator = UIImpactFeedbackGenerator(style: .medium)
//                                                generator.impactOccurred()
//                                            }
//                                        }
//                                    }
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
                        scrollProxy.scrollTo(firstFriend.id, anchor: UnitPoint(x: 0.5, y: 0.5))

                        if let profileImageUrl = firstFriend.profileImageUrl {
                            selectedProfileImageUrl = profileImageUrl
                        } else {
                            selectedProfileImageUrl = nil
                        }
                        
                        if let receiverUid = firstFriend.uid as String? {
                            self.receiverUid = receiverUid
                        } else {
                            self.receiverUid = nil
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
