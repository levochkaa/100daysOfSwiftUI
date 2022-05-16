import SwiftUI

struct ExpenseItem: Identifiable, Codable, Equatable {
    var id = UUID()
    let name: String
    let type: String
    let amount: Double
}

class Expenses: ObservableObject {
    @Published var personal = [ExpenseItem]() {
        didSet {
            if let encoded = try? JSONEncoder().encode(personal) {
                UserDefaults.standard.set(encoded, forKey: "personal")
            }
        }
    }
    @Published var business = [ExpenseItem]() {
        didSet {
            if let encoded = try? JSONEncoder().encode(business) {
                UserDefaults.standard.set(encoded, forKey: "business")
            }
        }
    }

    init() {
        if let savedItems = UserDefaults.standard.data(forKey: "personal") {
            if let decodedItems = try? JSONDecoder().decode([ExpenseItem].self, from: savedItems) {
                personal = decodedItems.filter { $0.type == "Personal" }
            }
        }
        if let savedItems = UserDefaults.standard.data(forKey: "business") {
            if let decodedItems = try? JSONDecoder().decode([ExpenseItem].self, from: savedItems) {
                business = decodedItems.filter { $0.type == "Business" }
            }
        }
    }
}

struct AddView: View {

    @ObservedObject var expenses: Expenses

    @State private var name = ""
    @State private var type = "Personal"
    @State private var amount = 0.0

    @Environment(\.dismiss) var dismiss

    let types = ["Personal", "Business"]

    var body: some View {
        NavigationView {
            Form {
                TextField("Name", text: $name)
                Picker("Type", selection: $type) {
                    ForEach(types, id: \.self) {
                        Text($0)
                    }
                }
                .pickerStyle(.segmented)
                TextField("Amount", value: $amount, format: .currency(code: Locale.current.currencyCode ?? "USD"))
                    .keyboardType(.decimalPad)
            }
            .navigationTitle("Add new expense")
            .toolbar {
                Button("Save") {
                    let item = ExpenseItem(name: name, type: type, amount: amount)
                    if type == "Personal" {
                        expenses.personal.append(item)
                    } else {
                        expenses.business.append(item)
                    }
                    dismiss()
                }
            }
        }
    }
}

struct iExpenseView: View {

    @State private var showingAddExpense = false

    @StateObject var expenses = Expenses()

    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(expenses.personal) { item in
                        HStack {
                            Text(item.name)
                                .font(.headline)
                            Spacer()
                            Text(item.amount, format: .currency(code: Locale.current.currencyCode ?? "USD"))
                                .background(item.amount < 10.0 ? Color.green : item.amount < 100.0 ? Color.blue : Color.red)
                        }
                    }
                    .onDelete(perform: removePersonal)
                } header: {
                    Text("Personal")
                }
                .headerProminence(.increased)
                Section {
                    ForEach(expenses.business) { item in
                        HStack {
                            Text(item.name)
                                .font(.headline)
                            Spacer()
                            Text(item.amount, format: .currency(code: Locale.current.currencyCode ?? "USD"))
                                .background(item.amount < 10.0 ? Color.green : item.amount < 100.0 ? Color.blue : Color.red)
                        }
                    }
                    .onDelete(perform: removeBusiness)
                } header: {
                    Text("Business")
                }
                .headerProminence(.increased)
            }
            .sheet(isPresented: $showingAddExpense) {
                AddView(expenses: expenses)
            }
            .navigationTitle("iExpense")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddExpense = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }

    func removePersonal(at offsets: IndexSet) {
        expenses.personal.remove(atOffsets: offsets)
    }

    func removeBusiness(at offsets: IndexSet) {
        expenses.business.remove(atOffsets: offsets)
    }
}

struct iExpenseView_Previews: PreviewProvider {
    static var previews: some View {
        iExpenseView().preferredColorScheme(.dark)
    }
}
