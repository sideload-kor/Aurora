//
//  TabbarView.swift
//  Aurora
//

import SwiftUI

struct TabbarView: View {
    @State private var selectedTab: TabEnum = .sources

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(TabEnum.defaultTabs, id: \.self) { tab in
                TabEnum.view(for: tab)
                    .tabItem {
                        Label(tab.title, systemImage: tab.icon)
                    }
                    .tag(tab)
            }
        }
        .tint(.orange)
        .background(Color(.systemBackground))
    }
}

// Kept as a tiny wrapper so FeatherApp can use Aurora's navigation container
// without requiring another source file to be added to the Xcode project.
struct VariedTabbarView: View {
    var body: some View {
        TabbarView()
    }
}
