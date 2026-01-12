//
//  FullScreenImageViewer.swift
//  KickIn
//
//  Created by 서준일 on 01/11/26
//

import SwiftUI
import OSLog
import AVKit
import CachingKit

// MARK: - VideoPlayerView

/// 서버 썸네일을 표시하고, 재생 버튼 클릭 시 비디오 다운로드 및 재생
struct VideoPlayerView: View {
    let videoURL: URL
    let thumbnailURL: URL
    let cachingKit: CachingKit

    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var isLoading = false
    @State private var downloadProgress: Double = 0.0

    var body: some View {
        ZStack {
            if let player = player, isPlaying {
                // 비디오 재생 중
                VideoPlayer(player: player)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                    .onDisappear {
                        player.pause()
                    }
            } else {
                // 썸네일 표시
                CachedAsyncImage(
                    url: thumbnailURL,
                    targetSize: CGSize(width: 1000, height: 1000),
                    cachingKit: cachingKit
                ) { image in
                    image
                        .resizable()
                        .scaledToFit()
                } placeholder: {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                .overlay(
                    ZStack {
                        // 재생 버튼
                        if !isLoading {
                            Button {
                                Task { await startPlayback() }
                            } label: {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 64))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.3), radius: 4)
                            }
                        }

                        // 로딩 인디케이터
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                                .padding()
                                .background(Circle().fill(Color.black.opacity(0.5)))
                        }
                    }
                )
            }

            // 다운로드 진행률
            if downloadProgress > 0 && downloadProgress < 1.0 {
                VStack {
                    Spacer()
                    ProgressView(value: downloadProgress)
                        .progressViewStyle(LinearProgressViewStyle())
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }
            }
        }
    }

    /// 비디오 재생 시작
    private func startPlayback() async {
        guard !isLoading else { return }

        isLoading = true

        do {
            // 비디오 다운로드 및 캐싱
            let localURL = try await cachingKit.loadVideo(
                url: videoURL,
                cacheStrategy: .diskOnly,
                headers: nil,
                progressHandler: { progress in
                    Task { @MainActor in
                        downloadProgress = progress
                    }
                }
            )

            await MainActor.run {
                player = AVPlayer(url: localURL)
                player?.play()
                isPlaying = true
                isLoading = false
                downloadProgress = 0.0
            }
        } catch {
            await MainActor.run {
                isLoading = false
                downloadProgress = 0.0
            }
            Logger.ui.error("❌ Failed to play video: \(error.localizedDescription)")
        }
    }
}

// MARK: - FullScreenImageViewer

struct FullScreenImageViewer: View {
    @Environment(\.cachingKit) private var cachingKit

    let mediaItems: [MediaItem]
    let initialIndex: Int
    @Binding var isPresented: Bool

    @State private var currentIndex: Int
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @GestureState private var magnifyBy: CGFloat = 1.0

    init(mediaItems: [MediaItem], initialIndex: Int, isPresented: Binding<Bool>) {
        self.mediaItems = mediaItems
        self.initialIndex = initialIndex
        self._isPresented = isPresented
        self._currentIndex = State(initialValue: initialIndex)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentIndex) {
                ForEach(mediaItems.indices, id: \.self) { index in
                    let item = mediaItems[index]

                    if item.type == .video {
                        // 비디오: 서버 썸네일 사용 + VideoPlayer
                        if let videoURL = item.url.thumbnailURL,
                           let thumbnailURL = item.thumbnailURL?.thumbnailURL {

                            VideoPlayerView(
                                videoURL: videoURL,
                                thumbnailURL: thumbnailURL,
                                cachingKit: cachingKit
                            )
                            .tag(index)
                        }
                    } else {
                        // 이미지: CachedAsyncImage 사용
                        if let imageURL = item.url.thumbnailURL {
                            CachedAsyncImage(
                                url: imageURL,
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
            }
            .tabViewStyle(.page(indexDisplayMode: mediaItems.count > 1 ? .automatic : .never))
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
            if mediaItems.count > 1 {
                VStack {
                    Spacer()
                    Text("\(currentIndex + 1) / \(mediaItems.count)")
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
