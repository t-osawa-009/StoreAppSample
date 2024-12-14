import SwiftUI
import Foundation

// https://zenn.dev/ueshun/articles/3ee837c881905e
struct CoordinatePreferenceKey: PreferenceKey {
    static var defaultValue: [UUID: CGRect] = [:]
    
    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

// MARK: - CoordinateModifier

struct CoordinateModifier: ViewModifier {
    let id: UUID
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: CoordinatePreferenceKey.self,
                        value: [id: proxy.frame(in: .global)]
                    )
                }
            )
    }
}

extension View {
    func reportCoordinates(using id: UUID) -> some View {
        self.modifier(CoordinateModifier(id: id))
    }
}
