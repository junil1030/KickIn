//
//  HomeView.swift
//  KickIn
//
//  Created by 서준일 on 12/18/25.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        Text("Home View")
            .navigationTitle("홈")
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
