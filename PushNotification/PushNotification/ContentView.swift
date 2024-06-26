import SwiftUI
import FirebaseFirestore
import FirebaseAuth

// implement PTT + LiveKit

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

