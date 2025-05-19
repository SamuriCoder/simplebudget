import SwiftUI

struct RewardGoalView: View {
    @ObservedObject var budgetStore: BudgetStore
    @State private var showingAddRewardSheet = false // For adding new rewards
    @State private var showingDepositSheet = false   // For depositing to existing rewards
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    // Sorting directly in ForEach to ensure view updates with sorted list
                    ForEach(budgetStore.rewards.sorted(by: { $0.priority < $1.priority })) { reward in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(reward.title)
                                .font(.headline)
                            
                            ProgressView(value: reward.progressAmount, total: reward.goalAmount)
                                .progressViewStyle(LinearProgressViewStyle())
                            
                            HStack {
                                Text("$\(String(format: "%.2f", reward.progressAmount))")
                                Text("of")
                                Text("$\(String(format: "%.2f", reward.goalAmount))")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                    .onDelete(perform: deleteRewards)
                }
                .navigationTitle("Reward Goals")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingAddRewardSheet = true
                        }) {
                            Image(systemName: "plus")
                        }
                    }
                }
                .sheet(isPresented: $showingAddRewardSheet) {
                    AddRewardView(budgetStore: budgetStore, showingAddReward: $showingAddRewardSheet)
                }

                // Button to open the Deposit sheet
                if !budgetStore.rewards.isEmpty {
                    Button {
                        showingDepositSheet = true
                    } label: {
                        Text("Deposit to Reward Goal")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding([.horizontal, .bottom])
                } else {
                    Text("Create a reward goal to start depositing.")
                        .padding()
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
            }
            .sheet(isPresented: $showingDepositSheet) {
                // Present DepositControlView as a sheet
                DepositControlView(budgetStore: budgetStore, isPresented: $showingDepositSheet)
            }
        }
    }
    
    private func deleteRewards(at offsets: IndexSet) {
        let sortedRewards = budgetStore.rewards.sorted(by: { $0.priority < $1.priority })
        let rewardsToDelete = offsets.map { sortedRewards[$0] }
        
        let originalIndices = IndexSet(rewardsToDelete.compactMap { rewardToDelete in
            budgetStore.rewards.firstIndex(where: { $0.id == rewardToDelete.id })
        })
        
        if !originalIndices.isEmpty {
            budgetStore.deleteReward(at: originalIndices)
        }
    }
}

// AddRewardView (no changes from previous version, included for completeness)
struct AddRewardView: View {
    @ObservedObject var budgetStore: BudgetStore
    @Binding var showingAddReward: Bool

    @State private var newRewardTitle = ""
    @State private var newRewardAmountString = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var isSaveDisabled: Bool {
        newRewardTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        newRewardAmountString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        (Double(newRewardAmountString) ?? 0) <= 0
    }

    var body: some View {
        NavigationView {
            Form {
                TextField("Reward Title", text: $newRewardTitle)
                TextField("Goal Amount", text: $newRewardAmountString)
                    .keyboardType(.decimalPad)
            }
            .navigationTitle("New Reward Goal")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingAddReward = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveNewReward()
                    }
                    .disabled(isSaveDisabled)
                }
            }
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Invalid Input"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    private func saveNewReward() {
        guard let amount = Double(newRewardAmountString), amount > 0 else {
            alertMessage = "Please enter a valid positive amount for the goal."
            showingAlert = true
            return
        }
        budgetStore.addReward(title: newRewardTitle.trimmingCharacters(in: .whitespacesAndNewlines), goalAmount: amount)
        showingAddReward = false
    }
}


// DepositControlView - Now designed to be presented in a sheet
struct DepositControlView: View {
    @ObservedObject var budgetStore: BudgetStore
    @Binding var isPresented: Bool // Binding to control the sheet's presentation

    @State private var selectedRewardId: UUID?
    @State private var depositAmountString: String = ""
    
    @State private var showingAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""

    var isDepositDisabled: Bool {
        selectedRewardId == nil ||
        depositAmountString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        (Double(depositAmountString) ?? 0) <= 0
    }

    var body: some View {
        NavigationView { // Wrap in NavigationView to get a navigation bar for title and 'X' button
            VStack(spacing: 20) {
                
                // Display Current Balance
                Text("Current Balance: $\(String(format: "%.2f", budgetStore.currentBalance))")
                    .font(.headline)
                    .padding(.top) // Add some padding above the balance
                    .foregroundColor(budgetStore.currentBalance < 0 ? .red : .green) // Optional: color code balance

                Picker("Select Reward", selection: $selectedRewardId) {
                    Text("Choose a reward...").tag(nil as UUID?) // Placeholder
                    ForEach(budgetStore.rewards.sorted(by: { $0.priority < $1.priority })) { reward in
                        Text("\(reward.title) (Goal: $\(String(format: "%.2f", reward.goalAmount)))")
                            .tag(reward.id as UUID?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(.horizontal)

                HStack {
                    Text("$")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    TextField("Amount to Deposit", text: $depositAmountString) // Added placeholder text
                        .keyboardType(.decimalPad)
                        .font(.title2)
                }
                .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
                
                Button(action: handleDeposit) {
                    Text("Deposit Funds")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isDepositDisabled ? Color.gray.opacity(0.5) : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(isDepositDisabled)
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 5) // Reduced top padding for the VStack as balance has its own
            .navigationTitle("Deposit to Reward")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark")
                            .imageScale(.large)
                    }
                }
            }
            .onAppear {
                if selectedRewardId == nil, let firstReward = budgetStore.rewards.sorted(by: { $0.priority < $1.priority }).first {
                    selectedRewardId = firstReward.id
                }
            }
            .alert(isPresented: $showingAlert) {
                Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    private func handleDeposit() {
        guard let rewardId = selectedRewardId else {
            alertTitle = "No Reward Selected"; alertMessage = "Please select a reward goal."; showingAlert = true; return
        }
        guard let depositAmount = Double(depositAmountString), depositAmount > 0 else {
            alertTitle = "Invalid Amount"; alertMessage = "Please enter a valid positive amount."; showingAlert = true; return
        }

        // Check if deposit amount exceeds current balance before calling budgetStore
        if depositAmount > budgetStore.currentBalance {
            alertTitle = "Insufficient Funds"
            alertMessage = "The amount you want to deposit ($\(String(format: "%.2f", depositAmount))) exceeds your current balance of $\(String(format: "%.2f", budgetStore.currentBalance))."
            showingAlert = true
            return
        }

        let result = budgetStore.depositToReward(rewardId: rewardId, amountToDeposit: depositAmount)
        alertTitle = result.success ? "Success!" : "Error"
        alertMessage = result.message
        showingAlert = true
        
        if result.success {
            depositAmountString = ""
        }
    }
}

