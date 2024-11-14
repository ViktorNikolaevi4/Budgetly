import SwiftUI
import SwiftData

struct RegularPaymentsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isCreateReminderViewPresented = false

    @Query private var regularPayments: [RegularPayment]

    var body: some View {
        VStack {
            List {
                ForEach(regularPayments) { payment in
                    HStack {
                        Text(payment.name)
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { payment.endDate == nil || payment.endDate! > Date() },
                            set: { _ in }
                        ))
                        .labelsHidden()
                    }
                }
            }

            Button(action: {
                isCreateReminderViewPresented = true
            }) {
                Text("+ СОЗДАТЬ")
                    .font(.headline)
                    .padding()
                    .foregroundColor(.blue)
            }
            .sheet(isPresented: $isCreateReminderViewPresented) {
                CreateReminderView()
            }
        }
        .navigationTitle("Регулярные платежи")
    }
}

#Preview {
    RegularPaymentsView()
}
