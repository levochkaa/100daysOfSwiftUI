import SwiftUI
import CoreData

class DataControllerBookworm: ObservableObject {
    let container = NSPersistentContainer(name: "Bookworm")

    init() {
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data failed to load: \(error.localizedDescription)")
            }
        }
    }
}

struct Bookworm: View {

    @State private var showingAddScreen = false

    @FetchRequest(sortDescriptors: [
        SortDescriptor(\.date, order: .reverse),
        SortDescriptor(\.title),
        SortDescriptor(\.author)
    ]) var books: FetchedResults<Book>

    @Environment(\.managedObjectContext) var moc

    var body: some View {
        NavigationView {
            List {
                ForEach(books) { book in
                    NavigationLink {
                        DetailView(book: book)
                    } label: {
                        HStack {
                            EmojiRatingView(rating: book.rating)
                                .font(.largeTitle)
                            VStack(alignment: .leading) {
                                Text(book.title ?? "Unknown Title")
                                    .font(.headline)
                                    .foregroundColor(book.rating == 1 ? .red : .white)
                                Text(book.author ?? "Unknown Author")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .onDelete(perform: deleteBooks)
            }
            .navigationTitle("Bookworm")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddScreen.toggle()
                    } label: {
                        Label("Add Book", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddScreen) {
                AddBookView()
            }
        }
    }

    func deleteBooks(at offsets: IndexSet) {
        for offset in offsets {
            let book = books[offset]
            moc.delete(book)
        }
        try? moc.save()
    }
}

struct DetailView: View {

    let book: Book

    @State private var showingDeleteAlert = false

    @Environment(\.managedObjectContext) var moc
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            ZStack(alignment: .bottomTrailing) {
                Image(book.genre ?? "Fantasy")
                    .resizable()
                    .scaledToFit()

                Text(book.genre?.uppercased() ?? "FANTASY")
                    .font(.caption)
                    .fontWeight(.black)
                    .padding(8)
                    .foregroundColor(.white)
                    .background(.black.opacity(0.75))
                    .clipShape(Capsule())
                    .offset(x: -5, y: -5)
            }
            Text(book.author ?? "Unknown author")
                .font(.title)
                .foregroundColor(.secondary)
            Text((book.review == "" ? "No Review" : book.review) ?? "No Review")
                .padding()
            RatingView(rating: .constant(Int(book.rating)))
                .font(.largeTitle)
            Text("Read on \(book.date?.formatted(date: .abbreviated, time: .omitted) ?? "Unknown")")
                .padding()
        }
        .navigationTitle(book.title ?? "Unknown Book")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button {
                showingDeleteAlert = true
            } label: {
                Label("Delete this book", systemImage: "trash")
            }
        }
        .alert("Delete book", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive, action: deleteBook)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure?")
        }
    }

    func deleteBook() {
        moc.delete(book)
         try? moc.save()
        dismiss()
    }
}

struct AddBookView: View {

    let genres = ["Fantasy", "Horror", "Kids", "Mystery", "Poetry", "Romance", "Thriller"]
    var check: Bool {
        title.isEmpty || author.isEmpty || genre.isEmpty || review.isEmpty
    }

    @State private var title = ""
    @State private var author = ""
    @State private var rating = 5
    @State private var genre = "Fantasy"
    @State private var review = ""

    @Environment(\.managedObjectContext) var moc
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Name of book", text: $title)
                    TextField("Author's name", text: $author)
                    Picker("Genre", selection: $genre) {
                        ForEach(genres, id: \.self) {
                            Text($0)
                        }
                    }
                    .pickerStyle(.wheel)
                }
                Section {
                    TextEditor(text: $review)
                    RatingView(rating: $rating)
                        .frame(maxWidth: .infinity)
                } header: {
                    Text("Write a review")
                }
                Section {
                    Button("Save") {
                        let newBook = Book(context: moc)
                        newBook.id = UUID()
                        newBook.title = title
                        newBook.author = author
                        newBook.rating = Int16(rating)
                        newBook.genre = genre
                        newBook.review = review
                        newBook.date = Date.now
                        try? moc.save()
                        dismiss()
                    }
                    .disabled(check)
                }
            }
            .navigationTitle("Add Book")
        }
    }
}

struct RatingView: View {

    @Binding var rating: Int

    var label = ""

    var maximumRating = 5

    var offImage: Image?
    var onImage = Image(systemName: "star.fill")

    var offColor = Color.gray
    var onColor = Color.yellow

    var body: some View {
        HStack {
            if !label.isEmpty {
                Text(label)
            }
            ForEach(1..<maximumRating + 1, id: \.self) { number in
                image(for: number)
                    .foregroundColor(number > rating ? offColor : onColor)
                    .onTapGesture {
                        rating = number
                    }
            }
        }
    }

    func image(for number: Int) -> Image {
        if number > rating {
            return offImage ?? onImage
        } else {
            return onImage
        }
    }
}

struct EmojiRatingView: View {
    let rating: Int16

    var body: some View {
        switch rating {
            case 1:
                Text("😡")
            case 2:
                Text("☹️")
            case 3:
                Text("😐")
            case 4:
                Text("☺️")
            default:
                Text("❤️")
        }
    }
}

struct Bookworm_Previews: PreviewProvider {
    static var dataController = DataControllerBookworm()
    static var previews: some View {
        Bookworm()
            .environment(\.managedObjectContext, dataController.container.viewContext)
            .preferredColorScheme(.dark)
    }
}
