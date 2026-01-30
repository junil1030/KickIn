//
//  ChatDetailView.swift
//  KickIn
//
//  Created by 서준일 on 01/05/26.
//

import SwiftUI
import Combine

struct ChatDetailView: View {
    @StateObject private var viewModel: ChatDetailViewModel
    @State private var messageText = ""
    @State private var selectedImages: [UIImage] = []
    @State private var selectedVideoURLs: [URL] = []
    @State private var selectedPDFURLs: [URL] = []
    @FocusState private var isInputFocused: Bool
    @State private var showMediaDrawer = false

    // Lifecycle management
    private let lifecycleManager = ChatLifecycleManager.shared
    @State private var reconnectionCancellable: AnyCancellable?

    // Store for lifecycle registration
    let roomId: String
    let opponentUserId: String
    let otherParticipantName: String

    init(roomId: String, opponentUserId: String, otherParticipantName: String) {
        self.roomId = roomId
        self.opponentUserId = opponentUserId
        self.otherParticipantName = otherParticipantName

        self._viewModel = StateObject(wrappedValue: ChatDetailViewModel(
            roomId: roomId,
            opponentUserId: opponentUserId
        ))
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            // 기존 채팅 UI
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

                            ForEach(viewModel.displayedChatItems.reversed()) { item in
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
                                        viewModel: viewModel,
                                        config: config,
                                        myUserId: viewModel.myUserId
                                    )
                                    .id(item.id)
                                }
                            }
                        }
                        .rotationEffect(.degrees(180))
                        .padding(.bottom, 16)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .rotationEffect(.degrees(180))
                    .onTapGesture {
                        isInputFocused = false
                    }
                    .onChange(of: viewModel.displayedChatItems.count) { _, _ in
                        // 새 메시지가 추가되면 스크롤
                        if let firstItem = viewModel.displayedChatItems.first {
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
                    selectedVideoURLs: $selectedVideoURLs,
                    selectedPDFURLs: $selectedPDFURLs,
                    isInputFocused: $isInputFocused,
                    onSend: {
                        Task {
                            await viewModel.sendMessage(
                                content: messageText.isEmpty ? nil : messageText,
                                images: selectedImages,
                                videos: selectedVideoURLs,
                                pdfs: selectedPDFURLs
                            )
                            messageText = ""
                            selectedImages = []
                            selectedVideoURLs = []
                            selectedPDFURLs = []
                            isInputFocused = false
                        }
                    }
                )
            }
            .navigationTitle(otherParticipantName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showMediaDrawer.toggle()
                        }
                    } label: {
                        Image(systemName: "inset.filled.righthalf.rectangle")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.black)
                    }
                }
            }
            .defaultBackground()
            .task {
                await setupAndLoad()
            }
            .onDisappear {
                cleanup()
            }
            .alert("오류", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("확인", role: .cancel) {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }

            // 미디어 서랍
            if showMediaDrawer {
                MediaDrawerView(
                    isPresented: $showMediaDrawer,
                    mediaItems: viewModel.allMediaItems
                )
                .transition(.move(edge: .trailing))
                .zIndex(1)
            }
        }
    }

    // MARK: - Private Methods

    private func setupAndLoad() async {
        // Register with chat state manager (for push notification suppression)
        await MainActor.run {
            ChatStateManager.shared.enterChatRoom(roomId)
        }

        // Register with lifecycle manager
        await MainActor.run {
            lifecycleManager.registerActiveChatRoom(
                roomId: roomId,
                opponentUserId: opponentUserId,
                viewModel: viewModel
            )
        }

        // Subscribe to reconnection events
        reconnectionCancellable = lifecycleManager.reconnectionNeededPublisher
            .filter { $0 == roomId }
            .sink { _ in
                Task {
                    await viewModel.performReconnectionWithGapFill()
                }
            }

        // Initial load
        await viewModel.loadInitialMessages()
    }

    private func cleanup() {
        reconnectionCancellable?.cancel()
        reconnectionCancellable = nil
        lifecycleManager.unregisterActiveChatRoom()
        ChatStateManager.shared.leaveChatRoom()
        viewModel.cleanup()
    }
}
