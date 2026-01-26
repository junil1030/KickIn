//
//  PreventingView.swift
//  KickIn
//
//  Created by 서준일 on 1/26/26.
//

import SwiftUI

struct PreventingView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("테스트") {
                    Text("Test Text")
                }
            }
            .navigationTitle("숨김 처리")
        }
        .mask {
            ScreenShotPreventerMask()
                .ignoresSafeArea()
        }
        .background {
            ContentUnavailableView(
                "캡쳐할 수 없어요",
                systemImage: "iphone.slash",
                description: Text("이 영상은 캡쳐할 수 없는 화면이에요")
            )
        }
    }
}

#Preview {
    PreventingView()
}

extension View {
    @ViewBuilder
    func screenshotPreventingMask(_ isEnabled: Bool) -> some View {
        self
            .mask {
                Group {
                    if isEnabled {
                        ScreenShotPreventerMask()
                    } else {
                        Rectangle()
                    }
                }
                .ignoresSafeArea()
            }
            .background {
                ContentUnavailableView(
                    "캡쳐할 수 없어요",
                    systemImage: "iphone.slash",
                    description: Text("이 영상은 캡쳐할 수 없는 화면이에요")
                )
            }
    }
}

struct ScreenShotPreventerMask: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UITextField()
        view.isSecureTextEntry = true
        view.text = ""
        view.isUserInteractionEnabled = false
        
        if let autoHideLayer = findAutoHideLayer(view: view) {
            autoHideLayer.backgroundColor = UIColor.white.cgColor
        } else {
            view.layer.sublayers?.last?.backgroundColor = UIColor.white.cgColor
        }
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        
    }
    
    func findAutoHideLayer(view: UIView) -> CALayer? {
        if let layers = view.layer.sublayers {
            if let layer = layers.first(where: {layer in
                layer.delegate.debugDescription.contains("UITextLayoutCanvasView")
            }) {
                return layer
            }
        }
        
        return nil
    }
}
