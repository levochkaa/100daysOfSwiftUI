import SwiftUI

struct ContentView: View {

    var frame: CGFloat {
        isZoomed ? 300 : 40
    }

    @Namespace private var animation

    @State private var isZoomed = false

    var body: some View {
        VStack {
            if !isZoomed {
                Spacer()
            }

            VStack {
                HStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.blue)
                        .frame(width: frame, height: frame)
                        .padding(.top, isZoomed ? 20 : 0)
                    if !isZoomed {
                        Text("Taylor Swift - 1989")
                            .font(.headline)
                            .matchedGeometryEffect(id: "AlbumTitle", in: animation)
                        Spacer()
                    }
                }
                if isZoomed {
                    Text("Taylor Swift - 1989")
                        .font(.headline)
                        .matchedGeometryEffect(id: "AlbumTitle", in: animation)
                        .padding(.bottom, 60)
                    Spacer()
                }
            }
            .onTapGesture {
                withAnimation(.spring()) {
                    isZoomed.toggle()
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .frame(height: isZoomed ? 400 : 60)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.dark)
    }
}
