//
//  ContentView.swift
//  SimpleBudget
//
//  Created by Pravin Balasingam on 5/18/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var budgetStore = BudgetStore()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(budgetStore: budgetStore)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            RewardGoalView(budgetStore: budgetStore)
                .tabItem {
                    Label("Rewards", systemImage: "gift.fill")
                }
                .tag(1)
            
            SettingsView(budgetStore: budgetStore, selectedTab: $selectedTab)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(2)
        }
    }
}

#Preview {
    ContentView()
}
