//
//  MainHeaderView.swift
//  KickIn
//
//  Created by 서준일 on 01/20/26.
//

import SwiftUI

struct MainHeaderView: View {
    @Binding var showFilterSheet: Bool
    @Binding var selectedSection: FilterSection?
    let currentFilter: EstateFilter?

    var body: some View {
        HStack(spacing: 8) {
            ForEach(FilterSection.allCases) { section in
                filterButton(for: section)
            }
        }
    }

    // MARK: - Private Views

    @ViewBuilder
    private func filterButton(for section: FilterSection) -> some View {
        Button(action: {
            selectedSection = section
            showFilterSheet = true
        }) {
            HStack(spacing: 4) {
                Text(section.rawValue)
                    .font(.body2(.pretendardMedium))
                    .foregroundColor(isActive(section) ? .brightWood : .gray75)

                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(isActive(section) ? .brightWood : .gray75)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isActive(section) ? Color.brightWood.opacity(0.1) : Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isActive(section) ? Color.brightWood : Color.gray45, lineWidth: 1)
            )
            .cornerRadius(8)
        }
    }

    // MARK: - Private Methods

    private func isActive(_ section: FilterSection) -> Bool {
        guard let filter = currentFilter else { return false }

        switch section {
        case .transactionType:
            return filter.transactionType != nil
        case .price:
            return filter.depositRange != nil || filter.monthlyRentRange != nil
        case .area:
            return filter.areaRange != nil
        case .floor:
            return !filter.selectedFloors.isEmpty && !filter.selectedFloors.contains(.all)
        case .amenity:
            return !filter.selectedAmenities.isEmpty
        }
    }
}
