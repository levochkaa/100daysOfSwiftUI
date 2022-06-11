import SwiftUI

struct Row: Identifiable, Codable {
    var id = UUID()
    var dices: [Dice]
}

struct Dice: Identifiable, Codable {
    var id = UUID()
    var result: String
}

extension DicesProject {
    @MainActor class ViewModel: ObservableObject {

        let savePath = FileManager.documentsDirectory.appendingPathComponent("savedDices")

        @Published private(set) var savedDices: [Row]

        init() {
            do {
                let data = try Data(contentsOf: savePath)
                savedDices = try JSONDecoder().decode([Row].self, from: data)
            } catch {
                savedDices = []
            }
        }

        func addRow(of dices: [Dice]) {
            savedDices.append(Row(dices: dices))
            saveData()
        }

        func removeRow(at offsets: IndexSet) {
            savedDices.remove(atOffsets: offsets)
            saveData()
        }

        func saveData() {
            do {
                let data = try JSONEncoder().encode(savedDices)
                try data.write(to: savePath, options: [.atomic, .completeFileProtection])
            } catch {
                print("Unable to save data.")
            }
        }
    }
}

struct DicesProject: View {

    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    var possibleResults: [Int] {
        Array(1...sides)
    }

    @State private var sides = 4
    @State private var possibleSides = [4, 6, 8, 10, 12, 20, 100]
    @State private var dicesCount = 1
    @State private var rolled = false
    @State private var timeDone = 0
    @State private var dices = [Dice]()
    @State private var feedback = UINotificationFeedbackGenerator()

    @StateObject private var viewModel = ViewModel()

    var body: some View {
        Form {
            Section {
                Picker("Slides", selection: $sides.animation()) {
                    ForEach(possibleSides, id: \.self) { possibleSide in
                        Text(String(possibleSide))
                    }
                }
                .pickerStyle(.segmented)
                Stepper("Dices: \(dicesCount)", value: $dicesCount.animation(), in: 1...6)
            } header: {
                Text("Select how many sides and dices")
            }
            Section {
                HStack {
                    ForEach(dices) { dice in
                        Spacer()
                        Text(dice.result)
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            } header: {
                Text("Result")
            }
            Section {
                Button("Roll") {
                    withAnimation {
                        timeDone = 0
                        rolled = true
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .font(.headline)
            }
            Section {
                ForEach(viewModel.savedDices.reversed()) { row in
                    HStack {
                        ForEach(row.dices) { dice in
                            Spacer()
                            Text(dice.result)
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .onDelete(perform: deleteResultsRow)
            } header: {
                Text("All results")
            }
        }
        .onAppear {
            setDices()
            feedback.prepare()
        }
        .onChange(of: dicesCount) { count in setDices() }
        .onReceive(timer) { time in
            if timeDone != 50 && rolled {
                timeDone += 1
                setDices(true)
                feedback.notificationOccurred(.success)
            } else if timeDone == 50 {
                timeDone = 0
                rolled = false
                viewModel.addRow(of: dices)
            }
        }
    }

    func deleteResultsRow(at offsets: IndexSet) {
        viewModel.removeRow(at: offsets)
    }

    func setDices(_ map: Bool = false) {
        dices = map ? Array(repeating: Dice(result: "0"), count: dicesCount).map { _ in Dice(result: getResult()) } : Array(repeating: Dice(result: "0"), count: dicesCount)
    }

    func getResult() -> String {
        return String(possibleResults.randomElement() ?? 0)
    }
}

struct DicesProject_Previews: PreviewProvider {
    static var previews: some View {
        DicesProject()
            .preferredColorScheme(.dark)
    }
}
