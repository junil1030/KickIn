//
//  InterestView.swift
//  KickIn
//
//  Created by 서준일 on 12/18/25.
//

import SwiftUI

struct InterestView: View {
    @StateObject private var viewModel = InterestViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // 필터 및 정렬 섹션
            HStack(spacing: 0) {
                // 필터 버튼들
                HStack(spacing: 4) {
                    ForEach(FilterType.allCases, id: \.self) { filterType in
                        FilterButton(
                            title: filterType.rawValue,
                            isSelected: viewModel.selectedFilter == filterType
                        ) {
                            viewModel.selectFilter(filterType)
                        }
                    }
                }

                Spacer()

                // 정렬 버튼
                SortButton(isDescending: viewModel.isDescending) {
                    viewModel.toggleSortOrder()
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            // 매물 리스트
            if viewModel.estates.isEmpty && !viewModel.isLoading {
                // Empty State
                VStack {
                    Spacer()
                    Text("관심있는 매물을 찜해보세요!")
                        .font(.body1(.pretendardBold))
                        .foregroundColor(.gray90)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.estates) { estate in
                            NavigationLink(destination: EstateDetailView(estateId: estate.id)) {
                                InterestEstateCell(estate: estate)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .onAppear {
                                Task {
                                    await viewModel.loadMoreIfNeeded(currentItem: estate)
                                }
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
        .navigationTitle("관심 매물")
        .navigationBarTitleDisplayMode(.inline)
        .defaultBackground()
        .task {
            await viewModel.loadData()
        }
    }
}

#Preview {
    NavigationStack {
        InterestView()
    }
}
