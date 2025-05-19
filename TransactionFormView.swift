import SwiftUI

struct TransactionFormView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var budgetStore: BudgetStore
    var transactionType: TransactionType
    
    @State private var amount: String = ""
    @State private var reason: String = ""
    @State private var type: TransactionType
    @State private var date = Date()
    @State private var category: TransactionCategory = .misc
    
    init(budgetStore: BudgetStore, transactionType: TransactionType) {
        self.budgetStore = budgetStore
        self.transactionType = transactionType
        _type = State(initialValue: transactionType)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Transaction Details")) {
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    
                    TextField("Reason", text: $reason)
                    
                    if type == .expense {
                        Picker("Category", selection: $category) {
                            ForEach(TransactionCategory.allCases) { cat in
                                Text(cat.rawValue).tag(cat)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    } else {
                        EmptyView()
                    }
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
            }
            .navigationTitle("New Transaction")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    saveTransaction()
                }
                .disabled(amount.isEmpty || reason.isEmpty)
            )
            .onAppear {
                type = transactionType
                if transactionType == .income {
                    category = .rewardDeposit
                }
            }
        }
    }
    
    private func saveTransaction() {
        guard let amountDouble = Double(amount) else { return }
        let finalCategory = type == .expense ? category : .rewardDeposit
        budgetStore.addTransaction(amount: amountDouble, reason: reason, type: type, category: finalCategory)
        dismiss()
    }
} 
