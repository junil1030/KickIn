//
//  ChatRoomListView.swift
//  KickIn
//
//  Created by 서준일 on 01/05/26.
//

import SwiftUI
import OSLog

struct ChatRoomListView: View {
    @StateObject private var viewModel = ChatRoomListViewModel()
    @Binding var pendingChatRoomId: String?
    @State private var isNavigatingToChat = false
    @State private var targetChatRoom: (roomId: String, opponentUserId: String, opponentName: String)?

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading {
                // Loading State
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.chatRooms.isEmpty {
                // Empty State
                VStack(spacing: 16) {
                    Spacer()

                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 48))
                        .foregroundColor(.gray60)

                    Text("아직 채팅방이 없습니다")
                        .font(.body1(.pretendardBold))
                        .foregroundColor(.gray90)

                    Text("매물에 관심을 표시하고\n대화를 시작해보세요!")
                        .font(.body2(.pretendardMedium))
                        .foregroundColor(.gray75)
                        .multilineTextAlignment(.center)

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Success State - 채팅방 목록
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.chatRooms) { chatRoom in
                            NavigationLink(destination: ChatDetailView(
                                roomId: chatRoom.id,
                                opponentUserId: chatRoom.otherParticipant.userId,
                                otherParticipantName: chatRoom.otherParticipant.nickname
                            )) {
                                ChatRoomCell(chatRoom: chatRoom)
                            }
                            .buttonStyle(PlainButtonStyle())

                            Divider()
                                .background(Color.gray30)
                        }
                    }
                }
            }

            // 에러 표시
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.body2(.pretendardMedium))
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .navigationTitle("채팅")
        .navigationBarTitleDisplayMode(.inline)
        .defaultBackground()
        .navigationDestination(isPresented: $isNavigatingToChat) {
            if let target = targetChatRoom {
                ChatDetailView(
                    roomId: target.roomId,
                    opponentUserId: target.opponentUserId,
                    otherParticipantName: target.opponentName
                )
            }
        }
        .task {
            await viewModel.loadChatRooms()
        }
        .onChange(of: pendingChatRoomId) { _, newRoomId in
            handleDeepLink(roomId: newRoomId)
        }
        .onChange(of: viewModel.chatRooms) { _, _ in
            // 채팅방 목록이 로드된 후에 pending 딥링크 처리
            handleDeepLink(roomId: pendingChatRoomId)
        }
    }

    private func handleDeepLink(roomId: String?) {
        guard let roomId = roomId else { return }

        // 채팅방 목록에서 해당 채팅방 찾기
        if let chatRoom = viewModel.chatRooms.first(where: { $0.id == roomId }) {
            Logger.chat.info("[ChatRoomListView] Found chat room, navigating to: \(roomId)")
            targetChatRoom = (
                roomId: chatRoom.id,
                opponentUserId: chatRoom.otherParticipant.userId,
                opponentName: chatRoom.otherParticipant.nickname
            )
            isNavigatingToChat = true

            // 딥링크 처리 완료 후 상태 리셋
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                DeepLinkManager.shared.resetNavigation()
            }
        } else {
            Logger.chat.warning("[ChatRoomListView] Chat room not found in list: \(roomId)")
        }
    }
}

#Preview {
    NavigationStack {
        ChatRoomListView(pendingChatRoomId: .constant(nil))
    }
}
