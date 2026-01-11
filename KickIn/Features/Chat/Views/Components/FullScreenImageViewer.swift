//
//  FullScreenImageViewer.swift
//  KickIn
//
//  Created by 서준일 on 01/11/26
//

import SwiftUI
import CachingKit

struct FullScreenImageViewer: View {
    @Environment(\.cachingKit) private var cachingKit

    let imageURLs: [String]
    let initialIndex: Int
    @Binding var isPresented: Bool

    @State private var currentIndex: Int
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @GestureState private var magnifyBy: CGFloat = 1.0

    init(imageURLs: [String], initialIndex: Int, isPresented: Binding<Bool>) {
        self.imageURLs = imageURLs
        self.initialIndex = initialIndex
        self._isPresented = isPresented
        self._currentIndex = State(initialValue: initialIndex)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentIndex) {
                ForEach(imageURLs.indices, id: \.self) { index in
                    if let url = imageURLs[index].thumbnailURL {
                        CachedAsyncImage(
                            url: url,
                            targetSize: CGSize(width: 1000, height: 1000),
                            cachingKit: cachingKit
                        ) { image in
                            image
                                .resizable()
                                .scaledToFit()
                                .scaleEffect(scale * magnifyBy)
                                .gesture(magnificationGesture)
                        } placeholder: {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        .tag(index)
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: imageURLs.count > 1 ? .automatic : .never))
            .onChange(of: currentIndex) { _, _ in
                // 이미지 변경 시 줌 리셋
                withAnimation {
                    scale = 1.0
                    lastScale = 1.0
                }
            }

            // 닫기 버튼
            VStack {
                HStack {
                    Spacer()
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    }
                    .padding()
                }
                Spacer()
            }

            // 이미지 카운터 (여러 이미지일 때만 표시)
            if imageURLs.count > 1 {
                VStack {
                    Spacer()
                    Text("\(currentIndex + 1) / \(imageURLs.count)")
                        .font(.body2(.pretendardMedium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(12)
                        .padding(.bottom, 50)
                }
            }
        }
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .updating($magnifyBy) { value, gestureState, _ in
                gestureState = value
            }
            .onEnded { value in
                scale = lastScale * value
                lastScale = scale

                // 줌 범위 제한 (0.5x ~ 3.0x)
                if scale < 0.5 {
                    withAnimation {
                        scale = 0.5
                        lastScale = 0.5
                    }
                } else if scale > 3.0 {
                    withAnimation {
                        scale = 3.0
                        lastScale = 3.0
                    }
                }

                // 더블탭처럼 작은 변화면 원래대로 리셋
                if abs(value - 1.0) < 0.1 {
                    withAnimation {
                        scale = 1.0
                        lastScale = 1.0
                    }
                }
            }
    }
}
