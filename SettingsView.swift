import SwiftUI

struct SettingsView: View {
    @ObservedObject var budgetStore: BudgetStore
    @State private var allowance: String = ""
    @Binding var selectedTab: Int
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Monthly Allowance")) {
                    TextField("Amount", text: $allowance)
                        .keyboardType(.decimalPad)
                        .onAppear {
                            allowance = String(format: "%.2f", budgetStore.allowance)
                        }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Save") {
                saveSettings()
            })
        }
    }
    
    private func saveSettings() {
        if let amount = Double(allowance) {
            budgetStore.allowance = amount
            selectedTab = 0 // Switch to Home tab
        }
    }
} 