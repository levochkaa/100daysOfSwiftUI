import SwiftUI
import CoreData

struct UserJSON: Codable, Identifiable {
    var id: String
    var isActive: Bool
    var name: String
    var age: Int
    var company: String
    var email: String
    var address: String
    var about: String
    var registered: Date
    var tags: [String]
    var friends: [FriendJSON]
}

struct FriendJSON: Codable, Identifiable {
    var id: String
    var name: String
}

class DataControllerCoreDataJSONChallenge: ObservableObject {
    let container = NSPersistentContainer(name: "CoreDataJSONChallenge")

    init() {
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data failed to load: \(error.localizedDescription)")
            }
            self.container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        }
    }
}

struct CoreDataJSONChallenge: View {

    @FetchRequest(sortDescriptors: []) var users: FetchedResults<CachedUser>

    @Environment(\.managedObjectContext) var moc

    var body: some View {
        NavigationView {
            List(users) { user in
                NavigationLink(destination: DetailUserView(user: user)) {
                    HStack {
                        Image(systemName: "circle.fill")
                            .foregroundColor(user.isActive ? Color.green : Color.red)
                        Text(user.wrappedName)
                            .font(.headline)
                    }
                }
            }
            .navigationTitle("Users")
        }
        .task {
            await loadData()
        }
    }

    func loadData() async {
        guard let url = URL(string: "https://www.hackingwithswift.com/samples/friendface.json") else {
            print("Invalid URL")
            return
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            if let decodedResponse = try? decoder.decode([UserJSON].self, from: data) {
                await MainActor.run {
                    for user in decodedResponse {
                        let newCachedUser = CachedUser(context: moc)
                        newCachedUser.id = user.id
                        newCachedUser.isActive = user.isActive
                        newCachedUser.name = user.name
                        newCachedUser.age = Int16(user.age)
                        newCachedUser.about = user.about
                        newCachedUser.company = user.company
                        newCachedUser.email = user.email
                        newCachedUser.address = user.address
                        newCachedUser.registered = user.registered
                        newCachedUser.tags = user.tags.joined(separator: ",")
                        for friend in user.friends {
                            let newFriend = CachedFriend(context: moc)
                            newFriend.id = friend.id
                            newFriend.name = friend.name
                            newCachedUser.addToCachedFriends(newFriend)
                        }
                    }
                    try? moc.save()
                }
            }
        } catch {
            print("Invalid data")
        }
    }
}

struct DetailUserView: View {

    @State var user: CachedUser

    var body: some View {
        Form {
            Section {
                Text("Registered: \(user.registered!.formatted(date: .long, time: .omitted))")
                HStack {
                    Image(systemName: "circle.fill")
                        .foregroundColor(user.isActive ? .green : .red)
                    Text(user.isActive ? "Is active" : "Not active")
                }
                Text("Age: \(user.age)")
                Text("Company: \(user.wrappedCompany)")
                Text("Email: \(user.wrappedEmail)")
                Text("Address: \(user.wrappedAddress)")
            } header: {
                Text("Info")
            }
            Section {
                Text(user.wrappedAbout)
                    .multilineTextAlignment(.leading)
            } header: {
                Text("About")
            }
            Section {
                ForEach(user.tagsArray, id: \.self) { tag in
                    Text(tag)
                }
            } header: {
                Text("Tags")
            }
            Section {
                ForEach(user.cachedFriendsArray, id: \.objectID) { friend in
                    Text(friend.wrappedName)
                }
            } header: {
                Text("Friends")
            }
        }
        .navigationTitle(user.wrappedName)
        .font(.headline)
    }
}

struct CoreDataJSONChallenge_Previews: PreviewProvider {
    static var dataController = DataControllerCoreDataJSONChallenge()
    static var previews: some View {
        CoreDataJSONChallenge()
            .environment(\.managedObjectContext, dataController.container.viewContext)
            .preferredColorScheme(.dark)
    }
}
