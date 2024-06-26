import SwiftUI
import FirebaseFirestore
import FirebaseAuth

// start with sending simple alert type push notification
// then send push-to-talk push notification
// then add livekit feature 

struct ContentView: View {
    @State private var isUserLoggedIn = false
    
    var body: some View {
        if isUserLoggedIn {
            HomeView(isUserLoggedIn: $isUserLoggedIn)
        } else {
            AuthView(isUserLoggedIn: $isUserLoggedIn)
                .onAppear {
                    self.checkAuthentication()
            }
        }
    }
    
    private func checkAuthentication() {
        if Auth.auth().currentUser != nil {
            isUserLoggedIn = true
        } else {
            isUserLoggedIn = false
        }
    }
}

#Preview {
    ContentView()
}

