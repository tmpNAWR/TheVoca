//
//  ShakeEffect.swift
//  GGomVoca
//
//  Created by tae on 2023/02/02.
//

import SwiftUI

// MARK: - Shake Effect
struct ShakeEffect: ViewModifier {
    @State private var isShaking = false
    
    var trigger: Bool
    
    func body(content: Content) -> some View { // Content는  수정자가 적용되는 곳 '위'까지의 View
        content
            .offset(x: isShaking ? -6 : .zero)
            .animation(.default.repeatCount(3).speed(6), value: isShaking)
            .onChange(of: trigger) { newValue in // isOverCount -> false로 갈 때도 발생하니까
                guard newValue else { return }
                isShaking = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isShaking = false
                }
            }
    }
}

extension View {
    func shakeEffect(trigger: Bool) -> some View {
        modifier(ShakeEffect(trigger: trigger))
    }
}
