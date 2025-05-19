import Foundation

enum TransactionType: String, Codable {
    case income
    case expense
}

enum TransactionCategory: String, Codable, CaseIterable, Identifiable {
    case food = "Food"
    case clothing = "Clothing"
    case transport = "Transport"
    case entertainment = "Entertainment"
    case rewardDeposit = "Reward Deposit"
    case misc = "Misc"

    var id: String { self.rawValue }
}

struct Transaction: Identifiable, Codable {
    let id: UUID
    let amount: Double
    let reason: String
    let type: TransactionType
    let date: Date
    let category: TransactionCategory

    init(id: UUID = UUID(), amount: Double, reason: String, type: TransactionType, date: Date = Date(), category: TransactionCategory = .misc) {
        self.id = id
        self.amount = amount
        self.reason = reason
        self.type = type
        self.date = date
        self.category = category
    }
}

struct RewardGoal: Identifiable, Codable {
    let id: UUID
    var title: String
    var goalAmount: Double
    var progressAmount: Double
    var priority: Int

    init(id: UUID = UUID(), title: String, goalAmount: Double, progressAmount: Double = 0, priority: Int) {
        self.id = id
        self.title = title
        self.goalAmount = goalAmount
        self.progressAmount = progressAmount
        self.priority = priority
    }
}

class BudgetStore: ObservableObject {
    @Published var allowance: Double
    @Published var transactions: [Transaction]
    @Published var rewards: [RewardGoal]
    @Published var lastResetDate: Date

    init(allowance: Double = 0) {
        self.allowance = allowance
        self.transactions = []
        self.rewards = []
        self.lastResetDate = Date()

        loadData()
        checkAndResetAllowance()
    }

    var currentBalance: Double {
        let income = transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        let expenses = transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        return allowance + income - expenses
    }

    var projectedSavings: Double { // This might still be useful for other features
        let income = transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
        let expenses = transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        return max(allowance + income - expenses, 0)
    }

    func addTransaction(amount: Double, reason: String, type: TransactionType, category: TransactionCategory) {
        let transaction = Transaction(amount: amount, reason: reason, type: type, category: category)
        transactions.append(transaction)
        saveData()
    }

    func addReward(title: String, goalAmount: Double) {
        let priority = (rewards.map(\.priority).max() ?? 0) + 1
        let reward = RewardGoal(title: title, goalAmount: goalAmount, priority: priority)
        rewards.append(reward)
        rewards.sort { $0.priority < $1.priority } // Keep rewards sorted by priority
        saveData()
    }

    func updateRewardProgress(rewardId: UUID, amount: Double) {
        if let index = rewards.firstIndex(where: { $0.id == rewardId }) {
            rewards[index].progressAmount += amount
            // Optional: Cap progress at goalAmount if desired
            // rewards[index].progressAmount = min(rewards[index].progressAmount, rewards[index].goalAmount)
            saveData()
        }
    }

    func depositToReward(rewardId: UUID, amountToDeposit: Double) -> (success: Bool, message: String) {
        guard amountToDeposit > 0 else {
            return (false, "Deposit amount must be positive.")
        }

        guard amountToDeposit <= self.currentBalance else {
            let currentBalFormatted = String(format: "%.2f", self.currentBalance)
            let depositAmtFormatted = String(format: "%.2f", amountToDeposit)
            return (false, "Insufficient funds. Your current balance is $\(currentBalFormatted). You tried to deposit $\(depositAmtFormatted).")
        }

        guard let rewardIndex = self.rewards.firstIndex(where: { $0.id == rewardId }) else {
            return (false, "Selected reward not found.")
        }
        let reward = self.rewards[rewardIndex]

        let transactionReason = "Deposited Reward: \(reward.title)"
        self.addTransaction(amount: amountToDeposit, reason: transactionReason, type: .expense, category: .rewardDeposit)

        self.updateRewardProgress(rewardId: rewardId, amount: amountToDeposit)
        
        let rewardTitle = reward.title
        let depositAmtFormatted = String(format: "%.2f", amountToDeposit)
        let newBalanceFormatted = String(format: "%.2f", self.currentBalance)
        return (true, "Successfully deposited $\(depositAmtFormatted) to \(rewardTitle). Your new balance is $\(newBalanceFormatted).")
    }

    func deleteTransaction(id: UUID) {
        transactions.removeAll { $0.id == id }
        saveData()
    }

    func deleteReward(at offsets: IndexSet) {
        // This method assumes 'offsets' are for the main 'rewards' array.
        // If called from a sorted view, ensure indices are correctly mapped before calling this.
        rewards.remove(atOffsets: offsets)
        saveData()
    }
    
    func clearAllTransactions() {
        transactions.removeAll()
        saveData()
    }

    private func checkAndResetAllowance() {
        let calendar = Calendar.current
        let now = Date()

        if !calendar.isDate(lastResetDate, inSameDayAs: now) &&
           calendar.component(.day, from: now) == 1 { // Example: Reset on the 1st of the month
            // Define your reset logic, e.g., clear transactions or reset allowance base
            // transactions.removeAll() // This was the original logic
            lastResetDate = now
            saveData()
        }
    }

    private func saveData() {
        if let encodedTransactions = try? JSONEncoder().encode(transactions) {
            UserDefaults.standard.set(encodedTransactions, forKey: "transactions")
        }
        if let encodedRewards = try? JSONEncoder().encode(rewards) {
            UserDefaults.standard.set(encodedRewards, forKey: "rewards")
        }
        UserDefaults.standard.set(allowance, forKey: "allowance")
        UserDefaults.standard.set(lastResetDate, forKey: "lastResetDate")
    }

    private func loadData() {
        if let transactionsData = UserDefaults.standard.data(forKey: "transactions"),
           let decodedTransactions = try? JSONDecoder().decode([Transaction].self, from: transactionsData) {
            transactions = decodedTransactions
        }

        if let rewardsData = UserDefaults.standard.data(forKey: "rewards"),
           let decodedRewards = try? JSONDecoder().decode([RewardGoal].self, from: rewardsData) {
            rewards = decodedRewards.sorted { $0.priority < $1.priority } // Ensure loaded rewards are sorted
        } else {
            rewards = [] // Initialize if no saved data
        }

        allowance = UserDefaults.standard.double(forKey: "allowance")
        lastResetDate = UserDefaults.standard.object(forKey: "lastResetDate") as? Date ?? Date()
    }
}
