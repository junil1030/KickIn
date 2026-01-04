//
//  PostInputFieldsView.swift
//  KickIn
//
//  Created by 서준일 on 01/03/26.
//

import SwiftUI

struct PostInputFieldsView: View {
    @Binding var title: String
    @Binding var content: String

    private let maxTitleLength = 20
    private let maxContentLength = 500

    private var titleCount: Int {
        title.count
    }

    private var contentCount: Int {
        content.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            titleSection()

            contentSection()
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Subviews

    private func titleSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("제목")
                .font(.body1(.pretendardBold))
                .foregroundStyle(Color.gray75)

            TextField("제목을 입력해주세요", text: $title)
                .font(.body1(.pretendardMedium))
                .foregroundStyle(Color.gray60)
                .padding(.horizontal, 12)
                .padding(.vertical, 14)
                .frame(height: 50)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray60, lineWidth: 1)
                )
                .onChange(of: title) { oldValue, newValue in
                    if newValue.count > maxTitleLength {
                        title = String(newValue.prefix(maxTitleLength))
                    }
                }

            HStack {
                Spacer()
                HStack(spacing: 0) {
                    Text("\(titleCount)")
                        .foregroundStyle(titleCount > maxTitleLength ? Color.red : Color.gray60)
                    Text("/\(maxTitleLength)")
                        .foregroundStyle(Color.gray60)
                }
                .font(.caption1(.pretendardMedium))
            }
        }
    }

    private func contentSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("내용")
                .font(.body1(.pretendardBold))
                .foregroundStyle(Color.gray75)

            ZStack(alignment: .topLeading) {
                if content.isEmpty {
                    Text("내용을 입력해주세요")
                        .font(.body1(.pretendardMedium))
                        .foregroundStyle(Color.gray60.opacity(0.5))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 14)
                }

                TextEditor(text: $content)
                    .font(.body1(.pretendardMedium))
                    .foregroundStyle(Color.gray60)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 10)
                    .frame(height: 130)
                    .scrollContentBackground(.hidden)
                    .onChange(of: content) { oldValue, newValue in
                        if newValue.count > maxContentLength {
                            content = String(newValue.prefix(maxContentLength))
                        }
                    }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray60, lineWidth: 1)
            )

            HStack {
                Spacer()
                HStack(spacing: 0) {
                    Text("\(contentCount)")
                        .foregroundStyle(contentCount > maxContentLength ? Color.red : Color.gray60)
                    Text("/\(maxContentLength)")
                        .foregroundStyle(Color.gray60)
                }
                .font(.caption1(.pretendardMedium))
            }
        }
    }
}

#Preview {
    @Previewable @State var title = ""
    @Previewable @State var content = ""

    PostInputFieldsView(
        title: $title,
        content: $content
    )
    .defaultBackground()
}
