//
//  EstateDetailOptionView.swift
//  KickIn
//
//  Created by 서준일 on 12/29/25.
//

import SwiftUI

struct EstateDetailOptionView: View {
    let options: EstateOptionsUIModel?
    let parkingCount: Int?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private let optionItems: [(name: String, iconName: String)] = [
        ("냉장고", "Option/Refrigerator"),
        ("세탁기", "Option/WashingMachine"),
        ("에어컨", "Option/AirConditioner"),
        ("옷장", "Option/Closet"),
        ("신발장", "Option/ShoeCabinet"),
        ("전자레인지", "Option/Microwave"),
        ("싱크대", "Option/Sink"),
        ("TV", "Option/Television")
    ]

    private var isRegularWidth: Bool {
        horizontalSizeClass == .regular
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 타이틀
            Text("옵션 정보")
                .font(.body2(.pretendardBold))
                .foregroundStyle(Color.gray75)
                .padding(.top, 10)
                .padding(.leading, 20)
                .padding(.bottom, 10)

            // 옵션 박스
            optionGridView
                .padding(.horizontal, 20)

            // 주차 정보
            if let parkingCount = parkingCount, parkingCount > 0 {
                parkingInfoView(count: parkingCount)
                    .padding(.top, 10)
                    .padding(.horizontal, 20)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 20)
    }
}

// MARK: - SubViews
private extension EstateDetailOptionView {

    var optionGridView: some View {
        let columnCount = isRegularWidth ? 8 : 4
        let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: columnCount)

        return LazyVGrid(columns: columns, spacing: 16) {
            ForEach(optionItems, id: \.name) { item in
                optionItemView(name: item.name, iconName: item.iconName, isAvailable: hasOption(item.name))
            }
        }
        .padding(20)
        .background(Color.gray0)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray30, lineWidth: 1)
        )
        .cornerRadius(16)
    }

    func optionItemView(name: String, iconName: String, isAvailable: Bool) -> some View {
        VStack(spacing: 8) {
            Image(iconName)
                .resizable()
                .renderingMode(.template)
                .frame(width: 24, height: 24)
                .foregroundStyle(isAvailable ? Color.gray75 : Color.gray30)

            Text(name)
                .font(.caption2(.pretendardMedium))
                .foregroundStyle(isAvailable ? Color.gray75 : Color.gray30)
        }
    }

    func parkingInfoView(count: Int) -> some View {
        HStack(spacing: 6) {
            Image("Option/Parking")
                .resizable()
                .renderingMode(.template)
                .frame(width: 20, height: 20)
                .foregroundStyle(Color.gray60)

            Text("세대별 차량 \(count)대 주차 가능")
                .font(.body3(.pretendardMedium))
                .foregroundStyle(Color.gray60)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.gray0)
        .overlay(
            Capsule()
                .stroke(Color.gray30, lineWidth: 1)
        )
        .clipShape(Capsule())
    }
}

// MARK: - Helpers
private extension EstateDetailOptionView {

    func hasOption(_ optionName: String) -> Bool {
        guard let options = options else { return false }

        let allOptions = [
            options.option1,
            options.option2,
            options.option3,
            options.option4,
            options.option5,
            options.option6,
            options.option7,
            options.option8,
            options.option9,
            options.option10
        ]

        return allOptions.compactMap { $0 }.contains(optionName)
    }
}

#Preview {
    VStack(spacing: 20) {
        // 모든 옵션 있음
        EstateDetailOptionView(
            options: EstateOptionsUIModel(
                option1: "냉장고",
                option2: "세탁기",
                option3: "에어컨",
                option4: "옷장",
                option5: "신발장",
                option6: "전자레인지",
                option7: "싱크대",
                option8: "TV",
                option9: nil,
                option10: nil
            ),
            parkingCount: 2
        )

        // 일부 옵션만
        EstateDetailOptionView(
            options: EstateOptionsUIModel(
                option1: "냉장고",
                option2: "세탁기",
                option3: "에어컨",
                option4: nil,
                option5: nil,
                option6: nil,
                option7: nil,
                option8: nil,
                option9: nil,
                option10: nil
            ),
            parkingCount: 0
        )

        // 옵션 없음
        EstateDetailOptionView(
            options: nil,
            parkingCount: nil
        )
    }
    .background(Color.gray15)
}
