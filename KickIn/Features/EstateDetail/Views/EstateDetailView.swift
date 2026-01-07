//
//  EstateDetailView.swift
//  KickIn
//
//  Created by 서준일 on 12/23/25.
//

import SwiftUI

struct EstateDetailView: View {
    @StateObject private var viewModel: EstateDetailViewModel
    private let estateId: String
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    init(estateId: String) {
        self.estateId = estateId
        _viewModel = StateObject(wrappedValue: EstateDetailViewModel(estateId: estateId))
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            detailScrollView()
            if isRegularWidth {
                floatingCTA()
            }
        }
        .defaultBackground()
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom) {
            if !isRegularWidth {
                bottomCTA()
            }
        }
        .navigationTitle(viewModel.estate?.title ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadData()
        }
    }

    private var isRegularWidth: Bool {
        horizontalSizeClass == .regular
    }

    private var likeIconName: String {
        isLiked ? "Icon/Like_Fill" : "Icon/Like_Empty"
    }

    private var likeIconColor: Color {
        isLiked ? Color.brightWood : Color.gray60
    }

    private var isLiked: Bool {
        viewModel.estate?.isLiked ?? false
    }

    private func detailScrollView() -> some View {
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

                EstateDetailPostBoardButton(estateId: estateId)

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
    }

    private func floatingCTA() -> some View {
        HStack(spacing: 12) {
            Button {
                Task {
                    await viewModel.toggleLike()
                }
            } label: {
                Image(likeIconName)
                    .renderingMode(.template)
                    .foregroundStyle(likeIconColor)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)

            Button {
                // TODO: reserve action
            } label: {
                Text("예약하기")
                    .font(.title1(.pretendardBold))
                    .foregroundStyle(Color.gray0)
                    .frame(minWidth: 120, minHeight: 48)
                    .padding(.horizontal, 8)
                    .background(Color.deepCream)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 6)
        .padding(.trailing, 24)
        .padding(.bottom, 24)
    }

    private func bottomCTA() -> some View {
        HStack(spacing: 12) {
            Button {
                Task {
                    await viewModel.toggleLike()
                }
            } label: {
                Image(likeIconName)
                    .renderingMode(.template)
                    .foregroundStyle(likeIconColor)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)

            Button {
                // TODO: reserve action
            } label: {
                Text("예약하기")
                    .font(.title1(.pretendardBold))
                    .foregroundStyle(Color.gray0)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(Color.deepCream)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.gray0)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: -2)
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
