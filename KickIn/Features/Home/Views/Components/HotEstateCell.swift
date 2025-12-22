//
//  HotEstateCell.swift
//  KickIn
//
//  Created by 서준일 on 12/19/25.
//

import SwiftUI
import CachingKit

struct HotEstateCell: View {
    let thumbnailURL: URL?
    let introduction: String
    let price: String
    let viewerCount: Int
    let dong: String
    let area: String
    let imageHeaders: [String: String]

    var body: some View {
        ZStack {
            // 배경 이미지
            CachedAsyncImage(
                url: thumbnailURL,
                targetSize: CGSize(width: 300, height: 100),
                headers: imageHeaders
            ) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 300, height: 100)
                    .clipped()
                    .cornerRadius(12)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray90)
                    .frame(width: 300, height: 100)
                    .cornerRadius(12)
                    .overlay {
                        ProgressView()
                    }
            }
            
            VStack {
                HStack {
                    // 왼쪽: Fire 아이콘
                    Image("Icon/Fire")
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(.gray0)
                        .frame(width: 24, height: 24)
                    
                    Spacer()
                    
                    // 오른쪽: 소개와 가격
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(introduction)
                            .font(.caption1(.yeongdeok))
                            .foregroundColor(.gray0)
                            .lineLimit(1)
                        
                        Text(price)
                            .font(.body1(.yeongdeok))
                            .foregroundColor(.gray0)
                            .fontWeight(.bold)
                    }
                }
                .padding(.horizontal, 10)
                
                Spacer()
                
                HStack {
                    // 왼쪽: 함께 보는 중 뱃지
                    Text("\(viewerCount)명이 함께 보는 중")
                        .font(.caption3())
                        .foregroundColor(.gray0)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray60.opacity(0.7))
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    // 오른쪽: 동네와 방 크기
                    HStack(spacing: 2) {
                        Text(dong)
                            .font(.caption2())
                            .foregroundColor(.gray45)
                        
                        Text("·")
                            .foregroundColor(.gray45)
                        
                        Text(area)
                            .font(.caption2())
                            .foregroundColor(.gray45)
                    }
                }
                .padding(.horizontal, 10)
            }
            .padding(.vertical, 10)
        }
        .frame(width: 300, height: 100)
    }
}

#Preview {
    HotEstateCell(
        thumbnailURL: nil,
        introduction: "역세권 풀옵션",
        price: "월세 500/50",
        viewerCount: 12,
        dong: "역삼동",
        area: "20평",
        imageHeaders: ["SeSACKey": APIConfig.apikey]
    )
}
