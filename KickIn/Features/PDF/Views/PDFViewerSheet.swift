//
//  PDFViewerSheet.swift
//  KickIn
//
//  Created by 서준일 on 01/23/26
//

import SwiftUI
import PDFKit

struct PDFViewerSheet: View {
    let pdfURL: URL
    let fileName: String
    @Binding var isPresented: Bool

    @StateObject private var viewModel = PDFViewerViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading {
                    // 로딩 상태
                    VStack(spacing: 16) {
                        ProgressView(value: viewModel.downloadProgress, total: 1.0)
                            .progressViewStyle(.linear)
                            .frame(maxWidth: 200)

                        Text("\(Int(viewModel.downloadProgress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("PDF 다운로드 중...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else if let errorMessage = viewModel.errorMessage {
                    // 에러 상태
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.red)

                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        Button("닫기") {
                            isPresented = false
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                } else if let localURL = viewModel.localPDFURL {
                    // PDF 표시
                    PDFKitView(url: localURL)
                        .ignoresSafeArea(edges: .bottom)
                } else {
                    // 초기 상태 (발생하지 않음)
                    ProgressView()
                }
            }
            .navigationTitle(fileName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") {
                        isPresented = false
                    }
                }
            }
        }
        .task {
            print("📄 [PDFViewerSheet] Opening PDF: \(fileName)")
            print("📄 [PDFViewerSheet] URL: \(pdfURL.absoluteString)")
            await viewModel.loadPDF(from: pdfURL)
        }
    }
}

// MARK: - PDFKitView

struct PDFKitView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = .systemBackground
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        if let document = PDFDocument(url: url) {
            pdfView.document = document
        }
    }
}

#Preview {
    PDFViewerSheet(
        pdfURL: URL(string: "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf")!,
        fileName: "sample.pdf",
        isPresented: .constant(true)
    )
}
