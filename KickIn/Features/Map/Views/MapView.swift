//
//  MapView.swift
//  KickIn
//
//  Created by 서준일 on 1/9/26.
//

import SwiftUI

struct MapView: View {
    @StateObject private var viewModel = MapViewModel()

    var body: some View {
        ZStack {
            NaverMapView(viewModel: viewModel)
                .ignoresSafeArea()

            // Loading indicator
            if viewModel.isLoading {
                VStack {
                    Spacer()
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                        Text("주변 매물 검색 중...")
                            .font(.caption)
                    }
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(8)
                    .shadow(radius: 4)
                    .padding(.bottom, 50)
                }
            }

            // Error message
            if let errorMessage = viewModel.errorMessage {
                VStack {
                    Spacer()
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(radius: 4)
                        .padding(.bottom, 50)
                }
            }
        }
    }
}

#Preview {
    MapView()
}
