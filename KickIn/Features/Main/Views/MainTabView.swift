//
//  MainTabView.swift
//  KickIn
//
//  Created by 서준일 on 12/18/25.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .home

    enum Tab {
        case home
        case interest
        case profile
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label {
                    Text("홈")
                } icon: {
                    Image(selectedTab == .home ? "TabBar/Home_Fill" : "TabBar/Home_Empty")
                        .renderingMode(.template)
                }
            }
            .tag(Tab.home)

            NavigationStack {
                InterestView()
            }
            .tabItem {
                Label {
                    Text("관심매물")
                } icon: {
                    Image(selectedTab == .interest ? "TabBar/Interest_Fill" : "TabBar/Interest_Empty")
                        .renderingMode(.template)
                }
            }
            .tag(Tab.interest)

            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label {
                    Text("프로필")
                } icon: {
                    Image(selectedTab == .profile ? "TabBar/Setting_Fill" : "TabBar/Setting_Empty")
                        .renderingMode(.template)
                }
            }
            .tag(Tab.profile)
        }
        .tint(.red)
    }
}

#Preview {
    MainTabView()
}
