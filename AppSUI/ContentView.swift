import SwiftUI

struct User: Identifiable {
    var id = "Taylor Swift"
}

struct ContentView: View {

    @State private var selectedUser: User? = nil
    @State private var isShowingUser = false

    var body: some View {
        NavigationView {
            Text("Hello, World!")
                .onTapGesture {
                    isShowingUser = true
                }
                .sheet(item: $selectedUser) { user in
                    Text(user.id)
                }
                .alert("Welcome", isPresented: $isShowingUser) { }

            Text("hi")

            Text("By")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.dark)
    }
}
