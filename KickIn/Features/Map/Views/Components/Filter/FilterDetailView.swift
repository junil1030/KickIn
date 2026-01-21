//
//  FilterDetailView.swift
//  KickIn
//
//  Created by 서준일 on 01/20/26.
//

import SwiftUI

struct FilterDetailView: View {
    @ObservedObject var viewModel: FilterViewModel
    @Binding var selectedSection: FilterSection?
    let onApply: (EstateFilter) -> Void
    let onReset: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 24) {
                        // 1. 거래 유형 섹션
                        SectionLayout(
                            title: FilterSection.transactionType.rawValue,
                            subtitle: FilterSection.transactionType.subtitle
                        ) {
                            HStack(spacing: 12) {
                                ForEach(TransactionType.allCases, id: \.self) { type in
                                    FilterCapsuleButton(
                                        title: type.rawValue,
                                        isSelected: viewModel.selectedTransactionType == type,
                                        action: {
                                            viewModel.toggleTransactionType(type)
                                        }
                                    )
                                }
                                Spacer()
                            }
                        }
                        .id(FilterSection.transactionType)

                        Divider()

                        // 2. 가격 섹션
                        SectionLayout(
                            title: FilterSection.price.rawValue,
                            subtitle: FilterSection.price.subtitle
                        ) {
                            VStack(spacing: 24) {
                                // 보증금
                                RangeSliderView(
                                    title: "보증금",
                                    steps: DepositRange.steps,
                                    range: $viewModel.depositRange,
                                    formatter: { PriceFormatter.format($0) }
                                )

                                // 월세
                                RangeSliderView(
                                    title: "월세",
                                    steps: MonthlyRentRange.steps,
                                    range: $viewModel.monthlyRentRange,
                                    formatter: { PriceFormatter.format($0) }
                                )
                            }
                        }
                        .id(FilterSection.price)

                        Divider()

                        // 3. 면적 섹션
                        SectionLayout(
                            title: FilterSection.area.rawValue,
                            subtitle: FilterSection.area.subtitle
                        ) {
                            RangeSliderViewDouble(
                                title: "전용 면적",
                                steps: AreaRange.steps,
                                range: $viewModel.areaRange,
                                formatter: { PriceFormatter.formatArea($0) }
                            )
                        }
                        .id(FilterSection.area)

                        Divider()

                        // 4. 층수 섹션
                        SectionLayout(
                            title: FilterSection.floor.rawValue,
                            subtitle: FilterSection.floor.subtitle
                        ) {
                            LazyVGrid(
                                columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ],
                                spacing: 12
                            ) {
                                ForEach(FloorOption.allCases, id: \.self) { floor in
                                    FilterCapsuleButton(
                                        title: floor.rawValue,
                                        isSelected: viewModel.selectedFloors.contains(floor),
                                        action: {
                                            viewModel.toggleFloor(floor)
                                        }
                                    )
                                }
                            }
                        }
                        .id(FilterSection.floor)

                        Divider()

                        // 5. 옵션 섹션
                        SectionLayout(
                            title: FilterSection.amenity.rawValue,
                            subtitle: FilterSection.amenity.subtitle
                        ) {
                            LazyVGrid(
                                columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible()),
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ],
                                spacing: 16
                            ) {
                                ForEach(AmenityOption.allCases, id: \.self) { amenity in
                                    amenityCell(for: amenity)
                                }
                            }
                        }
                        .id(FilterSection.amenity)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                }
                .onChange(of: selectedSection) { _, section in
                    if let section = section {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(section, anchor: .top)
                        }
                        selectedSection = nil  // 스크롤 후 리셋
                    }
                }
            }
            .navigationTitle("필터")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.gray75)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                bottomBar
            }
        }
    }

    // MARK: - Private Views

    @ViewBuilder
    private func amenityCell(for amenity: AmenityOption) -> some View {
        Button(action: {
            viewModel.toggleAmenity(amenity)
        }) {
            VStack(spacing: 8) {
                Image("Option/\(amenity.iconName)")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                    .foregroundColor(viewModel.selectedAmenities.contains(amenity) ? .brightWood : .gray60)

                Text(amenity.rawValue)
                    .font(.caption1(.pretendardMedium))
                    .foregroundColor(viewModel.selectedAmenities.contains(amenity) ? .brightWood : .gray75)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(viewModel.selectedAmenities.contains(amenity) ? Color.brightWood.opacity(0.1) : Color.gray0)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(viewModel.selectedAmenities.contains(amenity) ? Color.brightWood : Color.gray45, lineWidth: 1)
            )
            .cornerRadius(8)
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            // 초기화 버튼
            Button(action: {
                viewModel.resetAll()
                onReset()
            }) {
                Text("초기화")
                    .font(.body1(.pretendardBold))
                    .foregroundColor(.gray60)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.gray15)
                    .cornerRadius(8)
            }

            // 매물 보기 버튼
            Button(action: {
                onApply(viewModel.buildFilter())
                dismiss()
            }) {
                Text("매물 보기")
                    .font(.body1(.pretendardBold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.deepCoast)
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: -2)
    }
}
