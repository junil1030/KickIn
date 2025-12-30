//
//  EstateDetailDescriptionView.swift
//  KickIn
//
//  Created by 서준일 on 12/29/25.
//

import SwiftUI

struct EstateDetailDescriptionView: View {
    let description: String?

    private var descriptionParagraphs: [String] {
        guard let description = description else { return [] }

        // "." 또는 "\n"으로 split
        let paragraphs = description
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        return paragraphs
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 타이틀
            Text("상세 설명")
                .font(.body2(.pretendardBold))
                .foregroundStyle(Color.gray75)
                .padding(.top, 10)
                .padding(.leading, 20)
                .padding(.bottom, 10)

            // 설명 내용
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(descriptionParagraphs, id: \.self) { paragraph in
                    Text(paragraph)
                        .font(.body2(.pretendardRegular))
                        .foregroundStyle(Color.gray60)
                }
            }
            .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 20)
    }
}

#Preview {
    VStack(spacing: 20) {
        // "."으로 구분된 설명
        EstateDetailDescriptionView(
            description: "대학생 및 직장인에게 적합한 깔끔한 원룸입니다. 편의점, 카페가 가까우며 조용한 주거환경을 자랑합니다."
        )

        // "\n"으로 구분된 설명
        EstateDetailDescriptionView(
            description: "넓고 쾌적한 공간\n최신 시설 완비\n교통 편리"
        )

        // "."과 "\n" 혼합
        EstateDetailDescriptionView(
            description: "신축급 컨디션의 투룸입니다.\n채광이 우수하며 통풍이 잘 됩니다. 역세권 위치로 출퇴근이 편리합니다."
        )

        // 설명 없음
        EstateDetailDescriptionView(
            description: nil
        )
    }
    .background(Color.gray15)
}
