//
//  MainTabView.swift
//  KickIn
//
//  Created by 서준일 on 12/18/25.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: TabItem = .home
    @ObservedObject private var deepLinkManager = DeepLinkManager.shared

    enum TabItem {
        case home
        case interest
        case map
        case chat
        case profile
    }
    
    init() {
        UITabBar.appearance().unselectedItemTintColor = UIColor(Color.gray45)
    }
    
    var body: some View {
        GeometryReader { geometry in
            let screenSize = ScreenSize(
                width: geometry.size.width,
                height: geometry.size.height,
                safeAreaTop: geometry.safeAreaInsets.top,
                safeAreaBottom: geometry.safeAreaInsets.bottom
            )
            
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
                .tag(TabItem.home)
                
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
                .tag(TabItem.interest)
                
                NavigationStack {
                    MapView()
                }
                .tabItem {
                    Label {
                        Text("매물지도")
                    } icon: {
                        Image(systemName: "map")
                    }
                }
                .tag(TabItem.map)
                
                NavigationStack {
                    ChatRoomListView(pendingChatRoomId: $deepLinkManager.pendingChatRoomId)
                }
                .tabItem {
                    Label {
                        Text("채팅")
                    } icon: {
                        Image(systemName: selectedTab == .chat ? "bubble.left.and.bubble.right.fill" : "bubble.left.and.bubble.right")
                    }
                }
                .tag(TabItem.chat)
                
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
                .tag(TabItem.profile)
            }
            .tint(Color.gray90)
            .environment(\.screenSize, screenSize)
            .onChange(of: deepLinkManager.shouldNavigateToChat) { oldValue, newValue in
                if newValue {
                    selectedTab = .chat
                }
            }
            .onAppear {
                if deepLinkManager.shouldNavigateToChat {
                    selectedTab = .chat
                }
            }
        }
    }
}

#Preview {
    MainTabView()
}
