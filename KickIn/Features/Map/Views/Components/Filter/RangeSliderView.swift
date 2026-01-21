//
//  RangeSliderView.swift
//  KickIn
//
//  Created by 서준일 on 01/20/26.
//

import SwiftUI

/// 범위 슬라이더 뷰 (제네릭 타입 지원)
struct RangeSliderView<T: BinaryInteger & Comparable>: View {
    let title: String
    let steps: [T]
    @Binding var range: ClosedRange<T>
    let formatter: (T) -> String

    @State private var lowerHandleOffset: CGFloat = 0
    @State private var upperHandleOffset: CGFloat = 0
    @State private var isDraggingLower = false
    @State private var isDraggingUpper = false

    private let trackHeight: CGFloat = 4
    private let handleSize: CGFloat = 24

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.body2(.pretendardMedium))
                .foregroundColor(.gray75)

            // Range label
            Text(rangeLabel)
                .font(.body1(.pretendardBold))
                .foregroundColor(.gray90)

            // Slider track
            GeometryReader { geometry in
                let width = geometry.size.width - handleSize

                ZStack(alignment: .leading) {
                    // Background track
                    Rectangle()
                        .fill(Color.gray30)
                        .frame(height: trackHeight)
                        .cornerRadius(trackHeight / 2)

                    // Active range track
                    Rectangle()
                        .fill(Color.brightWood)
                        .frame(width: upperHandleOffset - lowerHandleOffset, height: trackHeight)
                        .cornerRadius(trackHeight / 2)
                        .offset(x: lowerHandleOffset + handleSize / 2)

                    // Lower handle
                    Circle()
                        .fill(Color.white)
                        .frame(width: handleSize, height: handleSize)
                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                        .overlay(
                            Circle()
                                .stroke(Color.brightWood, lineWidth: 2)
                        )
                        .offset(x: lowerHandleOffset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    isDraggingLower = true
                                    let newOffset = max(0, min(value.location.x, upperHandleOffset - 10))
                                    lowerHandleOffset = newOffset
                                    updateLowerValue(in: width)
                                }
                                .onEnded { _ in
                                    isDraggingLower = false
                                    snapLowerHandle(in: width)
                                }
                        )

                    // Upper handle
                    Circle()
                        .fill(Color.white)
                        .frame(width: handleSize, height: handleSize)
                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                        .overlay(
                            Circle()
                                .stroke(Color.brightWood, lineWidth: 2)
                        )
                        .offset(x: upperHandleOffset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    isDraggingUpper = true
                                    let newOffset = max(lowerHandleOffset + 10, min(value.location.x, width))
                                    upperHandleOffset = newOffset
                                    updateUpperValue(in: width)
                                }
                                .onEnded { _ in
                                    isDraggingUpper = false
                                    snapUpperHandle(in: width)
                                }
                        )
                }
                .onAppear {
                    updateHandlePositions(in: width)
                }
            }
            .frame(height: handleSize)
        }
    }

    // MARK: - Computed Properties

    private var rangeLabel: String {
        let minValue = steps.first ?? range.lowerBound
        let maxValue = steps.last ?? range.upperBound

        if range.lowerBound == minValue && range.upperBound == maxValue {
            return "전체"
        } else if range.lowerBound == minValue {
            return "\(formatter(range.upperBound)) 이하"
        } else if range.upperBound == maxValue {
            return "\(formatter(range.lowerBound)) 이상"
        } else {
            return "\(formatter(range.lowerBound)) ~ \(formatter(range.upperBound))"
        }
    }

    // MARK: - Private Methods

    private func updateHandlePositions(in width: CGFloat) {
        guard !steps.isEmpty else { return }

        let lowerIndex = steps.firstIndex(of: range.lowerBound) ?? 0
        let upperIndex = steps.firstIndex(of: range.upperBound) ?? (steps.count - 1)

        lowerHandleOffset = CGFloat(lowerIndex) / CGFloat(steps.count - 1) * width
        upperHandleOffset = CGFloat(upperIndex) / CGFloat(steps.count - 1) * width
    }

    private func updateLowerValue(in width: CGFloat) {
        let percentage = lowerHandleOffset / width
        let index = Int(round(percentage * CGFloat(steps.count - 1)))
        let clampedIndex = max(0, min(index, steps.count - 1))
        let newValue = steps[clampedIndex]

        if newValue <= range.upperBound {
            range = newValue...range.upperBound
        }
    }

    private func updateUpperValue(in width: CGFloat) {
        let percentage = upperHandleOffset / width
        let index = Int(round(percentage * CGFloat(steps.count - 1)))
        let clampedIndex = max(0, min(index, steps.count - 1))
        let newValue = steps[clampedIndex]

        if newValue >= range.lowerBound {
            range = range.lowerBound...newValue
        }
    }

    private func snapLowerHandle(in width: CGFloat) {
        let percentage = lowerHandleOffset / width
        let index = Int(round(percentage * CGFloat(steps.count - 1)))
        let clampedIndex = max(0, min(index, steps.count - 1))
        let snappedValue = steps[clampedIndex]

        range = snappedValue...range.upperBound
        updateHandlePositions(in: width)
    }

    private func snapUpperHandle(in width: CGFloat) {
        let percentage = upperHandleOffset / width
        let index = Int(round(percentage * CGFloat(steps.count - 1)))
        let clampedIndex = max(0, min(index, steps.count - 1))
        let snappedValue = steps[clampedIndex]

        range = range.lowerBound...snappedValue
        updateHandlePositions(in: width)
    }
}

// MARK: - Double Support

/// 범위 슬라이더 뷰 (Double 타입 지원)
struct RangeSliderViewDouble: View {
    let title: String
    let steps: [Double]
    @Binding var range: ClosedRange<Double>
    let formatter: (Double) -> String

    @State private var lowerHandleOffset: CGFloat = 0
    @State private var upperHandleOffset: CGFloat = 0
    @State private var isDraggingLower = false
    @State private var isDraggingUpper = false

    private let trackHeight: CGFloat = 4
    private let handleSize: CGFloat = 24

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.body2(.pretendardMedium))
                .foregroundColor(.gray75)

            // Range label
            Text(rangeLabel)
                .font(.body1(.pretendardBold))
                .foregroundColor(.gray90)

            // Slider track
            GeometryReader { geometry in
                let width = geometry.size.width - handleSize

                ZStack(alignment: .leading) {
                    // Background track
                    Rectangle()
                        .fill(Color.gray30)
                        .frame(height: trackHeight)
                        .cornerRadius(trackHeight / 2)

                    // Active range track
                    Rectangle()
                        .fill(Color.brightWood)
                        .frame(width: upperHandleOffset - lowerHandleOffset, height: trackHeight)
                        .cornerRadius(trackHeight / 2)
                        .offset(x: lowerHandleOffset + handleSize / 2)

                    // Lower handle
                    Circle()
                        .fill(Color.white)
                        .frame(width: handleSize, height: handleSize)
                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                        .overlay(
                            Circle()
                                .stroke(Color.brightWood, lineWidth: 2)
                        )
                        .offset(x: lowerHandleOffset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    isDraggingLower = true
                                    let newOffset = max(0, min(value.location.x, upperHandleOffset - 10))
                                    lowerHandleOffset = newOffset
                                    updateLowerValue(in: width)
                                }
                                .onEnded { _ in
                                    isDraggingLower = false
                                    snapLowerHandle(in: width)
                                }
                        )

                    // Upper handle
                    Circle()
                        .fill(Color.white)
                        .frame(width: handleSize, height: handleSize)
                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                        .overlay(
                            Circle()
                                .stroke(Color.brightWood, lineWidth: 2)
                        )
                        .offset(x: upperHandleOffset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    isDraggingUpper = true
                                    let newOffset = max(lowerHandleOffset + 10, min(value.location.x, width))
                                    upperHandleOffset = newOffset
                                    updateUpperValue(in: width)
                                }
                                .onEnded { _ in
                                    isDraggingUpper = false
                                    snapUpperHandle(in: width)
                                }
                        )
                }
                .onAppear {
                    updateHandlePositions(in: width)
                }
            }
            .frame(height: handleSize)
        }
    }

    // MARK: - Computed Properties

    private var rangeLabel: String {
        let minValue = steps.first ?? range.lowerBound
        let maxValue = steps.last ?? range.upperBound

        if range.lowerBound == minValue && range.upperBound == maxValue {
            return "전체"
        } else if range.lowerBound == minValue {
            return "\(formatter(range.upperBound)) 이하"
        } else if range.upperBound == maxValue {
            return "\(formatter(range.lowerBound)) 이상"
        } else {
            return "\(formatter(range.lowerBound)) ~ \(formatter(range.upperBound))"
        }
    }

    // MARK: - Private Methods

    private func updateHandlePositions(in width: CGFloat) {
        guard !steps.isEmpty else { return }

        let lowerIndex = steps.firstIndex(of: range.lowerBound) ?? 0
        let upperIndex = steps.firstIndex(of: range.upperBound) ?? (steps.count - 1)

        lowerHandleOffset = CGFloat(lowerIndex) / CGFloat(steps.count - 1) * width
        upperHandleOffset = CGFloat(upperIndex) / CGFloat(steps.count - 1) * width
    }

    private func updateLowerValue(in width: CGFloat) {
        let percentage = lowerHandleOffset / width
        let index = Int(round(percentage * CGFloat(steps.count - 1)))
        let clampedIndex = max(0, min(index, steps.count - 1))
        let newValue = steps[clampedIndex]

        if newValue <= range.upperBound {
            range = newValue...range.upperBound
        }
    }

    private func updateUpperValue(in width: CGFloat) {
        let percentage = upperHandleOffset / width
        let index = Int(round(percentage * CGFloat(steps.count - 1)))
        let clampedIndex = max(0, min(index, steps.count - 1))
        let newValue = steps[clampedIndex]

        if newValue >= range.lowerBound {
            range = range.lowerBound...newValue
        }
    }

    private func snapLowerHandle(in width: CGFloat) {
        let percentage = lowerHandleOffset / width
        let index = Int(round(percentage * CGFloat(steps.count - 1)))
        let clampedIndex = max(0, min(index, steps.count - 1))
        let snappedValue = steps[clampedIndex]

        range = snappedValue...range.upperBound
        updateHandlePositions(in: width)
    }

    private func snapUpperHandle(in width: CGFloat) {
        let percentage = upperHandleOffset / width
        let index = Int(round(percentage * CGFloat(steps.count - 1)))
        let clampedIndex = max(0, min(index, steps.count - 1))
        let snappedValue = steps[clampedIndex]

        range = range.lowerBound...snappedValue
        updateHandlePositions(in: width)
    }
}
