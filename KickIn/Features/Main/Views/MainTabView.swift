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
                    Label("홈", systemImage: "house")
                }
                .tag(TabItem.home)
                
                NavigationStack {
                    InterestView()
                }
                .tabItem {
                    Label("관심매물", systemImage: "heart")
                }
                .tag(TabItem.interest)
                
                NavigationStack {
                    MapView()
                }
                .tabItem {
                    Label("매물지도", systemImage: "map")
                }
                .tag(TabItem.map)
                
                NavigationStack {
                    ChatRoomListView(pendingChatRoomId: $deepLinkManager.pendingChatRoomId)
                }
                .tabItem {
                    Label("채팅", systemImage: "bubble.left.and.bubble.right")
                }
                .tag(TabItem.chat)
                
                NavigationStack {
                    ProfileView()
                }
                .tabItem {
                    Label("프로필", systemImage: "person")
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
