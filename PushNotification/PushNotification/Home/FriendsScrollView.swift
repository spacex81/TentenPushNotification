//import SwiftUI
//import SDWebImageSwiftUI
//
//struct FriendsScrollView: View {
//    @Binding var showAddView: Bool
//    @StateObject var friendViewModel: FriendViewModel
//    let circleSize: CGFloat
//    let cameraStrokeSize: CGFloat
//    
//    var body: some View {
//        ScrollView(.horizontal, showsIndicators: false) {
//            HStack(spacing: 23) {
//                GeometryReader { geometry in
//                    let midX = geometry.frame(in: .global).midX
//                    let screenWidth = UIScreen.main.bounds.width
//                    let scale = calculateScale(midX: midX, screenWidth: screenWidth)
//                    
//                    ShowAddViewButton(showAddView: $showAddView, circleSize: circleSize)
//                        .scaleEffect(scale)
//                        .frame(width: circleSize, height: circleSize)
//                }
//                .frame(width: circleSize, height: circleSize)
//                
//                ForEach(Array(friendViewModel.friends.enumerated()), id: \.element.id) { index, friend in
//                    GeometryReader { geometry in
//                        let midX = geometry.frame(in: .global).midX
//                        let screenWidth = UIScreen.main.bounds.width
//                        let scale = calculateScale(midX: midX, screenWidth: screenWidth)
//                        
//                        if let profileImageUrl = friend.profileImageUrl, let url = URL(string: profileImageUrl) {
//                            WebImage(url: url)
//                                .resizable()
//                                .scaledToFill()
//                                .frame(width: circleSize, height: circleSize)
//                                .clipShape(Circle())
//                                .scaleEffect(scale)
//                        } else {
//                            // for preview
//                            Image("profile_\(index + 2)")
//                                .resizable()
//                                .scaledToFill()
//                                .frame(width: circleSize, height: circleSize)
//                                .clipShape(Circle())
//                                .scaleEffect(scale)
//                        }
//                    }
//                    .frame(width: circleSize, height: circleSize)
//                }
//                
//                GeometryReader { geometry in
//                    let midX = geometry.frame(in: .global).midX
//                    let screenWidth = UIScreen.main.bounds.width
//                    let scale = calculateScale(midX: midX, screenWidth: screenWidth)
//                    
//                    ShowAddViewButton(showAddView: $showAddView, circleSize: circleSize)
//                        .scaleEffect(scale)
//                        .frame(width: circleSize, height: circleSize)
//                }
//                .frame(width: circleSize, height: circleSize)
//            }
//            .padding()
//        }
//    }
//    
//    private func calculateScale(midX: CGFloat, screenWidth: CGFloat) -> CGFloat {
//        let center = screenWidth / 2
//        let distance = abs(midX - center)
//        let maxDistance = screenWidth / 2
//        let threshold: CGFloat = 150
//        let factor: CGFloat = 0.3
//        
//        if distance < threshold {
//            return 1.0
//        } else {
//            let adjustedDistance = distance - threshold
//            let adjustedMaxDistance = maxDistance - threshold
//            return max(0.5, 1 - (adjustedDistance / adjustedMaxDistance) * factor)
//        }
//    }
//}
