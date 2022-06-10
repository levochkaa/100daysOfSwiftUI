// must apply only landscape orientation for this project

import SwiftUI

struct Card: Codable, Identifiable, Equatable {
    var id = UUID()
    let prompt: String
    let answer: String

    static let example = Card(prompt: "Who played the 13th Doctor in Doctor Who?", answer: "Jodie Whittaker")

    static func ==(lhs: Card, rhs: Card) -> Bool {
        lhs.prompt == rhs.prompt && lhs.answer == rhs.answer
    }
}

@MainActor class ViewModelFlashzilla: ObservableObject {

    let savePath = FileManager.documentsDirectory.appendingPathComponent("Cards")

    @Published var cards = [Card]()

    init() {
        loadData()
    }

    func loadData() {
        do {
            let data = try Data(contentsOf: savePath)
            cards = try JSONDecoder().decode([Card].self, from: data)
        } catch {
            cards = []
        }
    }

    func saveData() {
        do {
            let data = try JSONEncoder().encode(cards)
            try data.write(to: savePath, options: [.atomic, .completeFileProtection])
        } catch {
            print("Unable to save data.")
        }
    }
}

struct Flashzilla: View {

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    @State private var timeRemaining = 99
    @State private var isActive = true
    @State private var showingEditScreen = false

    @StateObject var viewModel = ViewModelFlashzilla()

    @Environment(\.scenePhase) var scenePhase
    @Environment(\.accessibilityVoiceOverEnabled) var voiceOverEnabled
    @Environment(\.accessibilityDifferentiateWithoutColor) var differentiateWithoutColor

    var body: some View {
        ZStack {
            Image(decorative: "background")
                .resizable()
                .ignoresSafeArea()
            VStack {
                Text("Time: \(timeRemaining)")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 5)
                    .background(.black.opacity(0.75))
                    .clipShape(Capsule())
                ZStack {
                    ForEach(viewModel.cards) { card in
                        let index = viewModel.cards.firstIndex(of: card)!
                        CardView(card: card) { isRight in
                            withAnimation {
                                removeCard(at: index, isRight: isRight)
                            }
                        }
                        .stacked(at: index, in: viewModel.cards.count)
                        .allowsHitTesting(index == viewModel.cards.count - 1)
                        .accessibilityHidden(index < viewModel.cards.count - 1)
                    }
                }
                .allowsHitTesting(timeRemaining > 0)
                if viewModel.cards.isEmpty {
                    Button("Start Again", action: resetCards)
                        .padding()
                        .background(.white)
                        .foregroundColor(.black)
                        .clipShape(Capsule())
                }
            }
            VStack {
                HStack {
                    Spacer()
                    Button {
                        showingEditScreen = true
                    } label: {
                        Image(systemName: "plus.circle")
                            .padding()
                            .background(.black.opacity(0.7))
                            .clipShape(Circle())
                    }
                }
                Spacer()
            }
            .foregroundColor(.white)
            .font(.largeTitle)
            .padding()
            if differentiateWithoutColor || voiceOverEnabled {
                VStack {
                    Spacer()
                    HStack {
                        Button {
                            withAnimation {
                                removeCard(at: viewModel.cards.count - 1, isRight: false)
                            }
                        } label: {
                            Image(systemName: "xmark.circle")
                                .padding()
                                .background(.black.opacity(0.7))
                                .clipShape(Circle())
                        }
                        .accessibilityLabel("Wrong")
                        .accessibilityHint("Mark your answer as being incorrect.")
                        Spacer()
                        Button {
                            withAnimation {
                                removeCard(at: viewModel.cards.count - 1, isRight: true)
                            }
                        } label: {
                            Image(systemName: "checkmark.circle")
                                .padding()
                                .background(.black.opacity(0.7))
                                .clipShape(Circle())
                        }
                        .accessibilityLabel("Correct")
                        .accessibilityHint("Mark your answer as being correct.")
                    }
                    .foregroundColor(.white)
                    .font(.largeTitle)
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showingEditScreen, onDismiss: resetCards) {
            EditCards(viewModel: viewModel)
        }
        .onAppear(perform: resetCards)
        .onReceive(timer) { time in
            guard isActive else { return }
            if timeRemaining > 0 {
                timeRemaining -= 1
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                if !viewModel.cards.isEmpty {
                    isActive = true
                }
            } else {
                isActive = false
            }
        }
    }

    func removeCard(at index: Int, isRight: Bool) {
        guard index >= 0 else { return }
        let card = viewModel.cards[index]
        viewModel.cards.remove(at: index)
        if !isRight {
            viewModel.cards.insert(Card(prompt: card.prompt, answer: card.answer), at: 0)
        }
    }

    func resetCards() {
        withAnimation {
            timeRemaining = 99
            isActive = true
            viewModel.loadData()
        }
    }
}

struct EditCards: View {

    @State private var newPrompt = ""
    @State private var newAnswer = ""

    @ObservedObject var viewModel: ViewModelFlashzilla

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                Section("Add new card") {
                    TextField("Prompt", text: $newPrompt)
                    TextField("Answer", text: $newAnswer)
                    Button("Add card", action: addCard)
                }
                Section {
                    ForEach(viewModel.cards) { card in
                        VStack(alignment: .leading) {
                            Text(card.prompt)
                                .font(.headline)
                            Text(card.answer)
                                .foregroundColor(.secondary)
                        }
                    }
                    .onDelete(perform: removeCards)
                }
            }
            .navigationTitle("Edit Cards")
            .toolbar {
                Button("Done", action: done)
            }
            .listStyle(.grouped)
            .onAppear {
                viewModel.loadData()
            }
        }
    }

    func done() {
        dismiss()
    }

    func addCard() {
        let trimmedPrompt = newPrompt.trimmingCharacters(in: .whitespaces)
        let trimmedAnswer = newAnswer.trimmingCharacters(in: .whitespaces)
        guard trimmedPrompt.isEmpty == false && trimmedAnswer.isEmpty == false else { return }
        let card = Card(prompt: trimmedPrompt, answer: trimmedAnswer)
        viewModel.cards.insert(card, at: 0)
        newPrompt = ""
        newAnswer = ""
        viewModel.saveData()
    }

    func removeCards(at offsets: IndexSet) {
        viewModel.cards.remove(atOffsets: offsets)
        viewModel.saveData()
    }
}

struct CardView: View {

    let card: Card
    var removal: ((_ isRight: Bool) -> Void)? = nil

    @State private var offset: CGSize = .zero
    @State private var isShowingAnswer = false
    @State private var feedback = UINotificationFeedbackGenerator()

    @Environment(\.accessibilityVoiceOverEnabled) var voiceOverEnabled
    @Environment(\.accessibilityDifferentiateWithoutColor) var differentiateWithoutColor

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .fill(.white.opacity(1 - Double(abs(offset.width / 50))))
                .shadow(radius: 10)
                .background(
                    RoundedRectangle(cornerRadius: 25, style: .continuous)
                        .fill(
                            differentiateWithoutColor
                                ? .white
                                : .white
                                    .opacity(1 - Double(abs(offset.width / 50)))

                        )
                        .background(
                            differentiateWithoutColor
                                ? nil
                                : RoundedRectangle(cornerRadius: 25, style: .continuous)
                                    .fill(offset.width > 0 ? .green : .red)
                        )
                        .shadow(radius: 10)
                )
            VStack {
                if voiceOverEnabled {
                    Text(isShowingAnswer ? card.answer : card.prompt)
                        .font(.largeTitle)
                        .foregroundColor(.black)
                } else {
                    Text(card.prompt)
                        .font(.largeTitle)
                        .foregroundColor(.black)
                    if isShowingAnswer {
                        Text(card.answer)
                            .font(.title)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(20)
            .multilineTextAlignment(.center)
        }
        .frame(width: 450, height: 250)
        .rotationEffect(.degrees(Double(offset.width / 5)))
        .offset(x: offset.width * 5, y: 0)
        .opacity(2 - Double(abs(offset.width / 50)))
        .accessibilityAddTraits(.isButton)
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    offset = gesture.translation
                    feedback.prepare()
                }
                .onEnded { _ in
                    if abs(offset.width) > 99 {
                        if offset.width > 0 {
                            feedback.notificationOccurred(.success)
                            removal?(true)
                        } else {
                            feedback.notificationOccurred(.error)
                            removal?(false)
                        }
                    } else {
                        withAnimation {
                            offset = .zero
                        }
                    }
                }
        )
        .onTapGesture {
            withAnimation {
                isShowingAnswer.toggle()
            }
        }
    }
}

extension View {
    func stacked(at position: Int, in total: Int) -> some View {
        let offset = Double(total - position)
        return self.offset(x: 0, y: offset * 10)
    }
}

struct Flashzilla_Previews: PreviewProvider {
    static var previews: some View {
        Flashzilla()
//            .preferredColorScheme(.dark)
    }
}
