//
//  EstateDetailAddressPriceView.swift
//  KickIn
//
//  Created by 서준일 on 12/29/25.
//

import SwiftUI

struct EstateDetailAddressPriceView: View {
    let latitude: Double?
    let longitude: Double?
    let deposit: Int?
    let monthlyRent: Int?
    let maintenanceFee: Int?
    let area: Double?

    @State private var addressText: String = ""
    private let geocodeService: GeocodeServiceProtocol

    init(
        latitude: Double?,
        longitude: Double?,
        deposit: Int?,
        monthlyRent: Int?,
        maintenanceFee: Int?,
        area: Double?,
        geocodeService: GeocodeServiceProtocol = GeocodeService()
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.deposit = deposit
        self.monthlyRent = monthlyRent
        self.maintenanceFee = maintenanceFee
        self.area = area
        self.geocodeService = geocodeService
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 주소
            if !addressText.isEmpty {
                Text(addressText)
                    .font(.body2(.pretendardMedium))
                    .foregroundStyle(Color.gray60)
            }

            // 가격
            priceText

            // 관리비 및 평수
            detailInfoText
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom , 20)
        .padding(.horizontal, 20)
        .task {
            addressText = await geocodeService.getDetailedLocationString(latitude: latitude, longitude: longitude)
        }
    }
}

// MARK: - SubViews
private extension EstateDetailAddressPriceView {

    var priceText: some View {
        HStack(spacing: 4) {
            // 전세/월세 라벨
            Text(rentalTypeLabel)
                .font(.title1(.yeongdeok))
                .foregroundStyle(Color.gray75)

            // 가격
            Text(priceLabel)
                .font(.title1(.pretendardBold))
                .foregroundStyle(Color.gray90)
        }
    }

    var detailInfoText: some View {
        HStack(spacing: 4) {
            // 관리비
            if let maintenanceFee = maintenanceFee {
                Text("관리비 \(formattedMaintenanceFee(maintenanceFee))")
            }

            if maintenanceFee != nil && area != nil {
                Text("•")
            }

            // 평수
            if let area = area {
                areaText(area)
            }
        }
        .font(.body2(.pretendardMedium))
        .foregroundStyle(Color.gray60)
    }

    func areaText(_ area: Double) -> Text {
        // m² 표시를 위한 AttributedString 사용
        let baseText = String(format: "%.1f", area)
        let mText = "m"
        let superscript = "2"

        var attributedString = AttributedString(baseText + mText)
        var superscriptPart = AttributedString(superscript)
        superscriptPart.baselineOffset = 6
        superscriptPart.font = .system(size: 10)

        attributedString.append(superscriptPart)

        return Text(attributedString)
    }
}

// MARK: - Computed Properties
private extension EstateDetailAddressPriceView {

    var rentalTypeLabel: String {
        guard let monthlyRent = monthlyRent else {
            return "전세"
        }
        return monthlyRent > 0 ? "월세" : "전세"
    }

    var priceLabel: String {
        guard let deposit = deposit else {
            return "가격 미정"
        }

        let depositInManwon = deposit / 10000

        if let monthlyRent = monthlyRent, monthlyRent > 0 {
            let monthlyRentInManwon = monthlyRent / 10000
            return "\(depositInManwon)/\(monthlyRentInManwon)"
        } else {
            return "\(depositInManwon)"
        }
    }

    func formattedMaintenanceFee(_ fee: Int) -> String {
        let feeInManwon = fee / 10000
        return "\(feeInManwon)만원"
    }
}

#Preview {
    VStack(spacing: 20) {
        // 월세
        EstateDetailAddressPriceView(
            latitude: 37.51925,
            longitude: 126.889557,
            deposit: 5000000,
            monthlyRent: 450000,
            maintenanceFee: 50000,
            area: 19.8
        )

        // 전세
        EstateDetailAddressPriceView(
            latitude: 37.5665,
            longitude: 126.9780,
            deposit: 30000000,
            monthlyRent: 0,
            maintenanceFee: 160000,
            area: 112.4
        )

        // 위경도 없음
        EstateDetailAddressPriceView(
            latitude: nil,
            longitude: nil,
            deposit: 10000000,
            monthlyRent: 600000,
            maintenanceFee: 80000,
            area: 33.5
        )
    }
    .background(Color.gray15)
}
