import SwiftUI

struct Resort: Codable, Identifiable, Comparable {
    let id: String
    let name: String
    let country: String
    let description: String
    let imageCredit: String
    let price: Int
    let size: Int
    let snowDepth: Int
    let elevation: Int
    let runs: Int
    let facilities: [String]

    var facilityTypes: [Facility] {
        facilities.map(Facility.init)
    }

    static func < (lhs: Resort, rhs: Resort) -> Bool {
        return lhs.name < rhs.name
    }

    static let allResorts: [Resort] = Bundle.main.decode("resorts.json")
    static let example = allResorts[0]
}

struct Facility: Identifiable {
    let id = UUID()
    var name: String

    private let icons = [
        "Accommodation": "house",
        "Beginners": "1.circle",
        "Cross-country": "map",
        "Eco-friendly": "leaf.arrow.circlepath",
        "Family": "person.3"
    ]

    private let descriptions = [
        "Accommodation": "This resort has popular on-site accommodation.",
        "Beginners": "This resort has lots of ski schools.",
        "Cross-country": "This resort has many cross-country ski routes.",
        "Eco-friendly": "This resort has won an award for environmental friendliness.",
        "Family": "This resort is popular with families."
    ]

    var description: String {
        if let message = descriptions[name] {
            return message
        } else {
            fatalError("Unknown facility type: \(name)")
        }
    }

    var icon: some View {
        if let iconName = icons[name] {
            return Image(systemName: iconName)
                .accessibilityLabel(name)
                .foregroundColor(.secondary)
        } else {
            fatalError("Unknown facility type: \(name)")
        }
    }
}

class FavoritesSnowSeeker: ObservableObject {

    private var resorts: Set<String>
    private let savePath = FileManager.documentsDirectory.appendingPathComponent("Favorites")

    init() {
        do {
            let data = try Data(contentsOf: savePath)
            resorts = try JSONDecoder().decode(Set<String>.self, from: data)
        } catch {
            resorts = []
        }
    }

    func contains(_ resort: Resort) -> Bool {
        resorts.contains(resort.id)
    }

    func add(_ resort: Resort) {
        objectWillChange.send()
        resorts.insert(resort.id)
        save()
    }

    func remove(_ resort: Resort) {
        objectWillChange.send()
        resorts.remove(resort.id)
        save()
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(resorts)
            try data.write(to: savePath, options: [.atomic, .completeFileProtection])
        } catch {
            print("Unable to save data.")
        }
    }
}

struct SnowSeeker: View {

    enum SortOrder {
        case none, alphabetic, country
    }

    let resorts: [Resort] = Bundle.main.decode("resorts.json")
    var orderedResorts: [Resort] {
        switch order {
            case .none:
                return resorts
            case .alphabetic:
                return resorts.sorted()
            case .country:
                return resorts.sorted { (lhs: Resort, rhs: Resort) in
                    return lhs.country < rhs.country
                }
        }
    }
    var filteredResorts: [Resort] {
        if searchText.isEmpty {
            return orderedResorts
        } else {
            return orderedResorts.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }

    @State private var searchText = ""
    @State private var showChangeOrderType = false
    @State private var order: SortOrder = .none

    @StateObject var favorites = FavoritesSnowSeeker()

    var body: some View {
        NavigationView {
            List(filteredResorts) { resort in
                NavigationLink {
                    ResortView(resort: resort)
                } label: {
                    HStack {
                        Image(resort.country)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 25)
                            .clipShape(
                                RoundedRectangle(cornerRadius: 5)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(.black, lineWidth: 1)
                            )
                        VStack(alignment: .leading) {
                            Text(resort.name)
                                .font(.headline)
                            Text("\(resort.runs) runs")
                                .foregroundColor(.secondary)
                        }
                        if favorites.contains(resort) {
                            Spacer()
                            Image(systemName: "heart.fill")
                                .accessibilityLabel("This is a favorite resort")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Resorts")
            .toolbar {
                Button("Sort") {
                    showChangeOrderType.toggle()
                }
            }
            .searchable(text: $searchText, prompt: "Search for a resort")
            .confirmationDialog("Order type", isPresented: $showChangeOrderType) {
                Button("Default") { order = .none }
                Button("Alphabetic") { order = .alphabetic }
                Button("Country") { order = .country }
            }

            WelcomeView()
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .environmentObject(favorites)
    }
}

struct ResortView: View {

    let resort: Resort

    @State private var selectedFacility: Facility?
    @State private var showingFacility = false

    @EnvironmentObject var favorites: FavoritesSnowSeeker

    @Environment(\.dynamicTypeSize) var typeSize
    @Environment(\.horizontalSizeClass) var sizeClass

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    Image(decorative: resort.id)
                        .resizable()
                        .scaledToFit()
                    Text(resort.imageCredit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .padding([.bottom, .trailing], 5)
                        .foregroundColor(.gray)
                }
                HStack {
                    if sizeClass == .compact && typeSize > .large {
                        VStack(spacing: 10) { ResortDetailsView(resort: resort) }
                        VStack(spacing: 10) { SkiDetailsView(resort: resort) }
                    } else {
                        ResortDetailsView(resort: resort)
                        SkiDetailsView(resort: resort)
                    }
                }
                .padding(.vertical)
                .background(Color.primary.opacity(0.1))

                Group {
                    Text(resort.description)
                        .padding(.vertical)

                    Text("Facilities")
                        .font(.headline)

                    HStack {
                        ForEach(resort.facilityTypes) { facility in
                            Button {
                                selectedFacility = facility
                                showingFacility = true
                            } label: {
                                facility.icon
                                    .font(.title)
                            }
                        }
                    }
                    .padding(.vertical)
                }
                .padding(.horizontal)
            }
            Button(favorites.contains(resort) ? "Remove from Favorites" : "Add to Favorites") {
                if favorites.contains(resort) {
                    favorites.remove(resort)
                } else {
                    favorites.add(resort)
                }
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .navigationTitle("\(resort.name), \(resort.country)")
        .navigationBarTitleDisplayMode(.inline)
        .alert(selectedFacility?.name ?? "More information", isPresented: $showingFacility, presenting: selectedFacility) { _ in
            //
        } message: { facility in
            Text(facility.description)
        }
    }
}

struct ResortDetailsView: View {

    let resort: Resort
    var size: String {
        switch resort.size {
            case 1:
                return "Small"
            case 2:
                return "Average"
            default:
                return "Large"
        }
    }
    var price: String {
        String(repeating: "$", count: resort.price)
    }

    var body: some View {
        Group {
            VStack {
                Text("Size")
                    .font(.caption.bold())
                Text(size)
                    .font(.title3)
            }

            VStack {
                Text("Price")
                    .font(.caption.bold())
                Text(price)
                    .font(.title3)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct SkiDetailsView: View {
    let resort: Resort

    var body: some View {
        Group {
            VStack {
                Text("Elevation")
                    .font(.caption.bold())
                Text("\(resort.elevation)m")
                    .font(.title3)
            }

            VStack {
                Text("Snow")
                    .font(.caption.bold())
                Text("\(resort.snowDepth)cm")
                    .font(.title3)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct WelcomeView: View {
    var body: some View {
        VStack {
            Text("Welcome to SnowSeeker!")
                .font(.largeTitle)

            Text("Please select a resort from the left-hand menu; swipe from the left edge to show it.")
                .foregroundColor(.secondary)
        }
    }
}

extension View {
    @ViewBuilder func phoneOnlyStackNavigationView() -> some View {
        if UIDevice.current.userInterfaceIdiom == .phone {
            self.navigationViewStyle(.stack)
        } else {
            self
        }
    }
}

struct SnowSeeker_Previews: PreviewProvider {
    static var previews: some View {
        SnowSeeker()
            .preferredColorScheme(.dark)
    }
}
