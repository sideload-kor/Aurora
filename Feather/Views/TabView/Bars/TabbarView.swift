//
//  TabbarView.swift
//  Aurora
//

import SwiftUI
import AltSourceKit

struct TabbarView: View {
    @AppStorage("Feather.userTintColor") private var tintHex: String = "#848ef9"
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
        .tint(Color(hex: tintHex))
        .background(Color(.systemBackground))
    }
}
