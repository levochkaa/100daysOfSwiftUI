import SwiftUI

struct LayoutGeometry: View {

    let colors: [Color] = [.red, .green, .blue, .orange, .pink, .purple, .yellow]

    var body: some View {
        GeometryReader { fullView in
            ScrollView(.vertical) {
                ForEach(0..<50) { index in
                    GeometryReader { geo in
                        Text("row \(index)")
                            .font(.title)
                            .frame(maxWidth: .infinity)
                            .background(Color(hue: min(geo.frame(in: .global).minY / fullView.size.height, 1),
                                              saturation: geo.frame(in: .global).minY / fullView.size.height,
                                              brightness: geo.frame(in: .global).minY / fullView.size.height))
                            .opacity(geo.frame(in: .global).minY / 200)
                            .scaleEffect(max(geo.frame(in: .global).minY / fullView.size.height, 0.5) > 1.5
                                         ? 1.5
                                         : max(geo.frame(in: .global).minY / fullView.size.height, 0.5))
                            .rotation3DEffect(.degrees(geo.frame(in: .global).minY - fullView.size.height / 2) / 5,
                                              axis: (x: 0, y: 1, z: 0))
                    }
                    .frame(height: 40)
                }
            }
        }
    }
}

struct LayoutGeometry_Previews: PreviewProvider {
    static var previews: some View {
        LayoutGeometry()
            .preferredColorScheme(.dark)
    }
}
