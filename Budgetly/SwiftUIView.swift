import SwiftUI

struct SwiftUIView: View {
    @State private var message: String = ""

    var body: some View {
        Text(message)
            .onAppear {
                Task {
                    message = await futchMessage()
                }
            }
    }
}

#Preview {
    SwiftUIView()
}

private func futchMessage() async -> String {
     try? await Task.sleep(for: .seconds(2))
    return "Hello World"
}
