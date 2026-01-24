//
//  PDFAttachmentCell.swift
//  KickIn
//
//  Created by 서준일 on 01/23/26
//

import SwiftUI

struct PDFAttachmentCell: View {
    let fileName: String
    let fileSize: Int64?
    let isSentByMe: Bool
    var onTap: (() -> Void)?

    var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: 12) {
                // PDF 아이콘
                Image(systemName: "doc.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.red)

                // 파일 정보
                VStack(alignment: .leading, spacing: 4) {
                    Text(fileName)
                    .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .foregroundColor(isSentByMe ? .white : .primary)

                    if let fileSize = fileSize {
                        Text(formatFileSize(fileSize))
                            .font(.caption)
                            .foregroundColor(isSentByMe ? .white.opacity(0.8) : .secondary)
                    }
                }

                Spacer()

                // 다운로드 아이콘
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSentByMe ? .white : .blue)
            }
            .padding(12)
            .frame(maxWidth: 280)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSentByMe ? Color.blue.opacity(0.2) : Color.gray.opacity(0.15))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSentByMe ? Color.blue.opacity(0.3) : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Private Methods

    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

#Preview {
    VStack(spacing: 20) {
        PDFAttachmentCell(
            fileName: "계약서.pdf",
            fileSize: 1_234_567,
            isSentByMe: true,
            onTap: {}
        )

        PDFAttachmentCell(
            fileName: "매우_긴_파일명을_가진_PDF_문서입니다_테스트용.pdf",
            fileSize: 4_500_000,
            isSentByMe: false,
            onTap: {}
        )

        PDFAttachmentCell(
            fileName: "document.pdf",
            fileSize: nil,
            isSentByMe: true,
            onTap: {}
        )
    }
    .padding()
}
