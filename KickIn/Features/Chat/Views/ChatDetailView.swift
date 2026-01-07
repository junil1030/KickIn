//
//  ChatDetailView.swift
//  KickIn
//
//  Created by 서준일 on 01/05/26.
//

import SwiftUI

struct ChatDetailView: View {
    @StateObject private var viewModel: ChatDetailViewModel
    @State private var messageText = ""
    @State private var selectedImages: [UIImage] = []

    let otherParticipantName: String

    init(roomId: String, opponentUserId: String, otherParticipantName: String) {
        self._viewModel = StateObject(wrappedValue: ChatDetailViewModel(
            roomId: roomId,
            opponentUserId: opponentUserId
        ))
        self.otherParticipantName = otherParticipantName
    }

    var body: some View {
        VStack(spacing: 0) {
            // 메시지 리스트
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        // 상단 로딩 인디케이터
                        if viewModel.isLoadingMore {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        }

                        ForEach(viewModel.chatItems.reversed()) { item in
                            switch item {
                            case .dateHeader(_, let formatted):
                                Text(formatted)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .id(item.id)

                            case .message(let config):
                                ChatMessageBubble(
                                    config: config,
                                    myUserId: viewModel.myUserId
                                )
                                .id(item.id)
//                                .onAppear {
//                                    // 마지막 메시지에 도달하면 더 로드
//                                    if case .message(let lastConfig) = viewModel.chatItems.last,
//                                       lastConfig.id == config.id {
//                                        Task {
//                                            await viewModel.loadMoreMessages()
//                                        }
//                                    }
//                                }
                            }
                        }
                    }
                    .rotationEffect(.degrees(180))
                }
                .rotationEffect(.degrees(180))
                .onChange(of: viewModel.chatItems.count) { _, _ in
                    // 새 메시지가 추가되면 스크롤
                    if let firstItem = viewModel.chatItems.first {
                        withAnimation {
                            proxy.scrollTo(firstItem.id, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            // 입력창
            ChatInputBar(
                messageText: $messageText,
                selectedImages: $selectedImages,
                onSend: {
                    Task {
                        await viewModel.sendMessage(
                            content: messageText.isEmpty ? nil : messageText,
                            images: selectedImages
                        )
                        messageText = ""
                        selectedImages = []
                    }
                }
            )
        }
        .navigationTitle(otherParticipantName)
        .navigationBarTitleDisplayMode(.inline)
        .defaultBackground()
        .task {
            await viewModel.loadInitialMessages()
        }
        .onDisappear {
            viewModel.disconnect()
        }
    }
}
