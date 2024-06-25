import SwiftUI
import SDWebImageSwiftUI

struct AddView: View {
    var profileImageUrl: String?
    var pin: String?
    @State private var showPinView = false
    @StateObject private var friendViewModel = FriendViewModel()
    
    var body: some View {
        VStack {
            if let profileImageUrl = profileImageUrl, let url = URL(string: profileImageUrl) {
                WebImage(url: url)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .padding()
            } else {
                Image(systemName: "person.crop.circle")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .padding()
            }
            
            Button {
                showPinView.toggle()
            } label: {
                HStack {
                    Image(systemName: "plus")
                        .font(.largeTitle).bold()
                    Text("add friends").font(.largeTitle).bold()
                }
            }
            .onChange(of: showPinView) { oldValue, newValue in
                if newValue {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                }
            }
            .sheet(isPresented: $showPinView) {
                PinView(myPin: pin)
            }
            
            VStack(alignment: .leading) {
                ForEach(friendViewModel.friends) { friend in
                    HStack {
                        if let profileImageUrl = friend.profileImageUrl, let url = URL(string: profileImageUrl) {
                            WebImage(url: url)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.crop.circle")
                                .resizable()
                                .frame(width: 50, height: 50)
                        }
                        Text(friend.username)
                            .font(.headline)
                            .padding(.leading, 10)
                    }
                    .padding(.vertical, 5)
                }
            }
            .padding()
        }
        .onAppear {
            friendViewModel.fetchFriends()
        }
    }
}

#Preview {
    AddView(profileImageUrl: "https://example.com/profile.jpg", pin: "2frna4m")
}
