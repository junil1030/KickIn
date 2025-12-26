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
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                EstateDetailTopImageView(thumbnails: viewModel.estate?.thumbnails)

                EstateDetailViewingCountView(likeCount: viewModel.estate?.likeCount)

                EstateDetailInfoHeaderView(
                    isSafeEstate: viewModel.estate?.isSafeEstate,
                    updatedAt: viewModel.estate?.updatedAt
                )
            }
            .frame(maxWidth: .infinity)
        }
        .defaultBackground()
        .navigationTitle(viewModel.estate?.title ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadData()
        }
    }
}

#Preview {
    EstateDetailView(estateId: "693a07fccd1a3725c019c953")
}
