//
//  EstateDetailView.swift
//  KickIn
//
//  Created by 서준일 on 12/23/25.
//

import SwiftUI

struct EstateDetailView: View {
    @StateObject private var viewModel: EstateDetailViewModel
    
    init(estateId: String) {
        _viewModel = StateObject(wrappedValue: EstateDetailViewModel(estateId: estateId))
    }
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    EstateDetailView(estateId: "693a07fccd1a3725c019c953")
}
