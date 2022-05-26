import SwiftUI

struct Activity: Codable, Identifiable, Equatable {
    var id = UUID()
    var title: String
    var description: String
    var times: Int = 0
}

class ViewModel: ObservableObject {
    @Published var activities = [Activity]() {
        didSet {
            if let encoded = try? JSONEncoder().encode(activities) {
                UserDefaults.standard.set(encoded, forKey: "activities")
            }
        }
    }
    init() {
        if let savedItems = UserDefaults.standard.data(forKey: "activities") {
            if let decodedItems = try? JSONDecoder().decode([Activity].self, from: savedItems) {
                activities = decodedItems
            }
        }
    }
}

struct HabitsView: View {

    @State private var showAddActivity = false

    @StateObject var data = ViewModel()

    var body: some View {
        NavigationView {
            List(data.activities) { activity in
                NavigationLink(destination: DetailActivityView(activity: activity, data: data)) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(activity.title)
                                .lineLimit(1)
                            Text(activity.description)
                                .lineLimit(1)
                                .foregroundColor(.gray)
                        }
                        .padding(5)
                        Spacer()
                        Text("\(activity.times)")
                    }
                }
            }
            .sheet(isPresented: $showAddActivity) {
                AddActivityView(data: data)
            }
            .navigationTitle("Habits")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddActivity = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}

struct DetailActivityView: View {

    @State var activity: Activity

    @ObservedObject var data: ViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("Description: \(activity.description)")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading)
            Text("Times done: \(activity.times)")
                .font(.title)
                .padding()
            Button("Increase") {
                let newActivity = Activity(title: activity.title, description: activity.description, times: activity.times + 1)
                let index = data.activities.firstIndex(of: activity)!
                data.activities[index] = newActivity
            }
        }
        .navigationTitle(activity.title)
    }
}

struct AddActivityView: View {

    @State private var title = ""
    @State private var description = ""

    @ObservedObject var data: ViewModel

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                TextField("Title", text: $title)
                TextField("Description", text: $description)
            }
            .navigationTitle("Add Activity")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        let activity = Activity(title: title, description: description)
                        data.activities.append(activity)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
        }
        }
    }
}

struct HabitsView_Previews: PreviewProvider {
    static var previews: some View {
        HabitsView().preferredColorScheme(.dark)
    }
}
