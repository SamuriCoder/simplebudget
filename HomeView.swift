import SwiftUI
import Charts

struct HomeView: View {
    @ObservedObject var budgetStore: BudgetStore
    @State private var showingTransactionForm = false
    @State private var transactionType: TransactionType = .expense

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Balance Card
                    VStack(spacing: 8) {
                        Text("Current Balance")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text("$\(String(format: "%.2f", budgetStore.currentBalance))")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(budgetStore.currentBalance >= 0 ? .green : .red)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)

                    // Quick Action Buttons
                    HStack(spacing: 20) {
                        Button(action: {
                            transactionType = .income
                            showingTransactionForm = true
                        }) {
                            VStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 30))
                                Text("Add Money")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(12)
                        }

                        Button(action: {
                            transactionType = .expense
                            showingTransactionForm = true
                        }) {
                            VStack {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 30))
                                Text("Spend Money")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }

                    // Recent Transactions with Running Balance
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recent Transactions")
                                .font(.headline)
                            Spacer()
                            Button(action: {
                                budgetStore.clearAllTransactions()
                            }) {
                                Text("Clear All")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.horizontal)

                        // Compute transactions with running balance
                        let sorted = budgetStore.transactions.sorted(by: { $0.date > $1.date }).prefix(5)
                        var runningBalance = budgetStore.currentBalance
                        let transactionsWithBalance = sorted.map { transaction -> (Transaction, Double) in
                            let result = (transaction, runningBalance)
                            if transaction.type == .income {
                                runningBalance -= transaction.amount
                            } else {
                                runningBalance += transaction.amount
                            }
                            return result
                        }

                        ForEach(transactionsWithBalance, id: \.0.id) { transaction, balanceAfter in
                            HStack(alignment: .top) {
                                Image(systemName: transaction.type == .income ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                    .foregroundColor(transaction.type == .income ? .green : .red)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(transaction.reason)
                                        .font(.subheadline)
                                    Text(transaction.date, style: .date)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("\(transaction.type == .income ? "+" : "-") $\(String(format: "%.2f", transaction.amount))")
                                        .foregroundColor(transaction.type == .income ? .green : .red)
                                    Text("Balance: $\(String(format: "%.2f", balanceAfter))")
                                        .font(.caption)
                                        .italic()
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)

                    // Pie Chart for expenses by category
                    let expenseTransactions = budgetStore.transactions.filter { $0.type == .expense }
                    let categoryTotals = Dictionary(grouping: expenseTransactions, by: { $0.category }).mapValues { $0.reduce(0) { $0 + $1.amount } }
                    if !categoryTotals.isEmpty {
                        VStack(alignment: .leading) {
                            Text("Spending by Category")
                                .font(.headline)
                                .padding(.leading)
                            Chart {
                                ForEach(Array(categoryTotals.keys), id: \ .self) { category in
                                    if let value = categoryTotals[category] {
                                        SectorMark(
                                            angle: .value("Amount", value),
                                            innerRadius: .ratio(0.5),
                                            angularInset: 2
                                        )
                                        .foregroundStyle(by: .value("Category", category.rawValue))
                                    }
                                }
                            }
                            .frame(height: 200)
                            .padding([.leading, .trailing])
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Budget")
            .sheet(isPresented: $showingTransactionForm) {
                TransactionFormView(budgetStore: budgetStore, transactionType: transactionType)
                    .id(transactionType)
            }
        }
    }
}
