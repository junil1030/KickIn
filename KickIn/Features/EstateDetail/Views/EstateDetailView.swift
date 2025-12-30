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

                EstateDetailAddressPriceView(
                    latitude: viewModel.estate?.geolocation?.latitude,
                    longitude: viewModel.estate?.geolocation?.longitude,
                    deposit: viewModel.estate?.deposit,
                    monthlyRent: viewModel.estate?.monthlyRent,
                    maintenanceFee: viewModel.estate?.maintenanceFee,
                    area: viewModel.estate?.area
                )

                divider()

                EstateDetailOptionView(
                    options: viewModel.estate?.options,
                    parkingCount: viewModel.estate?.parkingCount
                )

                divider()

                EstateDetailDescriptionView(
                    description: viewModel.estate?.description
                )

                divider()

                EstateDetailSimilarEstatesView(
                    estates: viewModel.similarEstates
                )

                divider()

                EstateDetailAgentInfoView(
                    creator: viewModel.estate?.creator
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
    
    private func divider() -> some View {
        return Divider()
            .background(Color.gray30)
            .padding(.horizontal, 20)
    }
}

#Preview {
    EstateDetailView(estateId: "693a07fccd1a3725c019c953")
}
