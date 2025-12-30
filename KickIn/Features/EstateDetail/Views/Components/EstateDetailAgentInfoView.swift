//
//  EstateDetailAgentInfoView.swift
//  KickIn
//
//  Created by 서준일 on 12/29/25.
//

import SwiftUI
import CachingKit

struct EstateDetailAgentInfoView: View {
    @Environment(\.cachingKit) private var cachingKit

    let creator: EstateCreatorUIModel?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 타이틀
            Text("중개사 정보")
                .font(.body2(.pretendardBold))
                .foregroundStyle(Color.gray75)
                .padding(.top, 10)
                .padding(.leading, 20)
                .padding(.bottom, 10)

            // 중개사 정보
            if let creator = creator {
                HStack(spacing: 12) {
                    // 왼쪽: 프로필 사진
                    profileImageView(creator.profileImage)

                    // 중앙: 이름 및 소개
                    VStack(alignment: .leading, spacing: 4) {
                        Text(creator.nick ?? "")
                            .font(.body2(.pretendardBold))
                            .foregroundStyle(Color.gray90)

                        Text(creator.introduction ?? "")
                            .font(.caption1(.pretendardRegular))
                            .foregroundStyle(Color.gray60)
                            .lineLimit(1)
                    }

                    Spacer()

                    // 오른쪽: 전화 및 메시지 버튼
                    HStack(spacing: 8) {
                        actionButton(iconName: "Icon/Phone") {
                            print("Phone button tapped")
                        }

                        actionButton(iconName: "Icon/Frame") {
                            print("Frame button tapped")
                        }
                    }
                }
                .padding(.horizontal, 20)
            } else {
                emptyView
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 60)
    }
}

// MARK: - SubViews
private extension EstateDetailAgentInfoView {

    func profileImageView(_ profileImage: String?) -> some View {
        Group {
            if let profileImage = profileImage,
               let imageURL = profileImage.thumbnailURL {
                CachedAsyncImage(
                    url: imageURL,
                    targetSize: CGSize(width: 48, height: 48),
                    cachingKit: cachingKit
                ) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                } placeholder: {
                    Circle()
                        .fill(Color.gray45)
                        .frame(width: 48, height: 48)
                        .overlay {
                            ProgressView()
                        }
                }
            } else {
                Circle()
                    .fill(Color.gray45)
                    .frame(width: 48, height: 48)
                    .overlay {
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray60)
                    }
            }
        }
    }

    func actionButton(iconName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(iconName)
                .resizable()
                .renderingMode(.template)
                .frame(width: 24, height: 24)
                .foregroundStyle(Color.gray0)
        }
        .frame(width: 40, height: 40)
        .background(Color.deepCream)
        .cornerRadius(8)
    }

    var emptyView: some View {
        Text("중개사 정보가 없습니다.")
            .font(.body2())
            .foregroundStyle(Color.gray60)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .padding(.horizontal, 20)
    }
}

#Preview {
    VStack(spacing: 20) {
        // 중개사 정보 있음
        EstateDetailAgentInfoView(
            creator: EstateCreatorUIModel(
                userId: "6938ceb8cd1a3725c019c8b9",
                nick: "핀공인중개사",
                introduction: "안녕하세요 :)",
                profileImage: "/data/profiles/1765331714972.png"
            )
        )

        // 긴 소개글
        EstateDetailAgentInfoView(
            creator: EstateCreatorUIModel(
                userId: "123",
                nick: "서울부동산",
                introduction: "20년 경력의 믿을 수 있는 중개사입니다. 언제든 연락주세요!",
                profileImage: nil
            )
        )

        // 중개사 정보 없음
        EstateDetailAgentInfoView(
            creator: nil
        )
    }
    .background(Color.gray15)
}
