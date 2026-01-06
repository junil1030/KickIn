//
//  ChatRoomListView.swift
//  KickIn
//
//  Created by 서준일 on 01/05/26.
//

import SwiftUI

struct ChatRoomListView: View {
    @StateObject private var viewModel = ChatRoomListViewModel()

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
        .task {
            await viewModel.loadChatRooms()
        }
    }
}

#Preview {
    NavigationStack {
        ChatRoomListView()
    }
}
