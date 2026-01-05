//
//  View+Toast.swift
//  KickIn
//
//  Created by 서준일 on 01/05/26.
//

import SwiftUI

struct ToastModifier: ViewModifier {
    @Binding var message: String?
    let duration: TimeInterval

    @State private var offset: CGFloat = 100
    @State private var workItem: DispatchWorkItem?

    func body(content: Content) -> some View {
        content
            .overlay(
                ZStack {
                    if let message = message {
                        VStack {
                            Spacer()
                            ToastView(message: message)
                                .padding(.bottom, 60)
                                .offset(y: offset)
                                .onAppear {
                                    showToast()
                                }
                                .onChange(of: message) {
                                        showToast()
                                }
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: message != nil)
            )
    }

    private func showToast() {
        // 기존 작업이 있다면 취소
        workItem?.cancel()

        // 애니메이션으로 토스트 표시
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            offset = 0
        }

        // 새로운 작업 생성
        let task = DispatchWorkItem { [self] in
            // 토스트 숨김 애니메이션
            withAnimation(.easeInOut(duration: 0.3)) {
                offset = 100
            }

            // 애니메이션 완료 후 message를 nil로 설정
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                message = nil
                offset = 100 // 다음 토스트를 위해 offset 초기화
            }
        }

        workItem = task
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: task)
    }
}

extension View {
    /// Toast 메시지를 표시합니다.
    /// - Parameters:
    ///   - message: 표시할 메시지를 담은 바인딩 (nil이 아닐 때 토스트 표시)
    ///   - duration: 토스트가 표시되는 시간 (기본값: 3초)
    ///
    /// ## 사용 예시
    /// ```swift
    /// struct SomeView: View {
    ///     @StateObject var viewModel = SomeViewModel()
    ///
    ///     var body: some View {
    ///         VStack {
    ///             // 뷰 내용
    ///         }
    ///         .toast(message: $viewModel.errorMessage)
    ///     }
    /// }
    ///
    /// // ViewModel에서 사용
    /// class SomeViewModel: ObservableObject {
    ///     @Published var errorMessage: String?
    ///
    ///     func doSomething() {
    ///         errorMessage = "작업이 완료되었습니다" // 토스트 자동 표시
    ///     }
    /// }
    /// ```
    func toast(
        message: Binding<String?>,
        duration: TimeInterval = 3.0
    ) -> some View {
        self.modifier(ToastModifier(
            message: message,
            duration: duration
        ))
    }
}
