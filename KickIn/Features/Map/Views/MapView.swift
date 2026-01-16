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

            // Current location button (bottom right)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        viewModel.moveToCurrentLocation()
                    }) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.deepCoast)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 100)
                }
            }

            // Loading indicator
            if viewModel.state.isLoading {
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
            if let errorMessage = viewModel.state.errorMessage {
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
