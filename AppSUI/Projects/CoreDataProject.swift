import SwiftUI
import CoreData

enum Predications {
    case beginsWith, contains
}

class DataControllerCoreData: ObservableObject {
    let container = NSPersistentContainer(name: "CoreDataProject")

    init() {
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data failed to load: \(error.localizedDescription)")
            }
            self.container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        }
    }
}

struct CoreDataProject: View {

    @State private var lastNameFilter = "A"

    @Environment(\.managedObjectContext) var moc

    var body: some View {
        VStack {
            FilteredList(predicate: .beginsWith, filterKey: "lastName", filterValue: lastNameFilter, sortDescriptors: [SortDescriptor(\Singer.firstName), SortDescriptor(\Singer.lastName)]) { (singer: Singer) in
                Text("\(singer.wrappedFirstName) \(singer.wrappedLastName)")
            }

            Button("Add Examples") {
                let taylor = Singer(context: moc)
                taylor.firstName = "Taylor"
                taylor.lastName = "Swift"

                let ed = Singer(context: moc)
                ed.firstName = "Ed"
                ed.lastName = "Sheeran"

                let adele = Singer(context: moc)
                adele.firstName = "Adele"
                adele.lastName = "Adkins"

                try? moc.save()
            }

            Button("Show A") {
                lastNameFilter = "A"
            }

            Button("Show S") {
                lastNameFilter = "S"
            }
        }
    }
}

struct FilteredList<T: NSManagedObject, Content: View>: View {

    let content: (T) -> Content

    @FetchRequest var fetchRequest: FetchedResults<T>

    init(predicate: Predications, filterKey: String, filterValue: String, sortDescriptors: [SortDescriptor<T>] = [], @ViewBuilder content: @escaping (T) -> Content) {
        let predicateString = "\(predicate)".uppercased()
        _fetchRequest = FetchRequest<T>(sortDescriptors: sortDescriptors, predicate: NSPredicate(format: "%K \(predicateString) %@", filterKey, filterValue))
        self.content = content
    }

    var body: some View {
        List(fetchRequest, id: \.self) { singer in
            self.content(singer)
        }
    }
}

struct CoreDataProject_Previews: PreviewProvider {
    static var dataController = DataControllerCoreData()
    static var previews: some View {
        CoreDataProject()
            .environment(\.managedObjectContext, dataController.container.viewContext)
            .preferredColorScheme(.dark)
    }
}
