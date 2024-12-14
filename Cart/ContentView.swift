import SwiftUI

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

// MARK: - Product Model

struct Product: Identifiable {
    let id: UUID
    let name: String
    let price: String
}

struct AddToCartAnimationExample: View {
    @State private var coordinates: [UUID: CGRect] = [:]
    @State private var showAnimation: Bool = false
    @State private var animationOffset: CGPoint = .zero
    @State private var animationScale: CGFloat = 1.0
    @State private var animationOpacity: Double = 1.0
    @State private var cartBounce: Bool = false
    
    private let products = [
        Product(id: UUID(), name: "Product 1", price: "$10"),
        Product(id: UUID(), name: "Product 2", price: "$20"),
        Product(id: UUID(), name: "Product 3", price: "$30")
    ]
    @Environment(\.safeAreaInsets) var safeAreaInsets
    private let cartID = UUID()
    
    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                ScrollView {
                    ForEach(products) { product in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(product.name)
                                    .font(.headline)
                                Text(product.price)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }.padding()
                            
                            Spacer()
                            Button(action: {
                                triggerAddToCartAnimation(for: product.id)
                            }) {
                                Text("Add to Cart")
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            .reportCoordinates(using: product.id)
                        }
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal, 15)
                    }
                }
                
                Spacer()
                
                HStack {
                    Spacer()
                    Image(systemName: "cart.fill")
                        .font(.largeTitle)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(8)
                        .scaleEffect(cartBounce ? 1.2 : 1.0)
                        .animation(.interpolatingSpring(stiffness: 300, damping: 10).delay(0.7), value: cartBounce)
                        .reportCoordinates(using: cartID)
                }.padding()
            }
            .onPreferenceChange(CoordinatePreferenceKey.self) { preferences in
                self.coordinates = preferences
            }
            
            if showAnimation {
                Circle()
                    .fill(Color.red)
                    .frame(width: 30, height: 30)
                    .scaleEffect(animationScale)
                    .opacity(animationOpacity)
                    .position(x: animationOffset.x, y: animationOffset.y)
            }
        }
    }
    
    private let animationDuration: Double = 0.7
    private let cartBounceDuration: Double = 0.3
    private let midAnimationDelay: Double = 0.7

    private func triggerAddToCartAnimation(for productID: UUID) {
        guard let itemFrame = coordinates[productID] else { return }
        
        // safeAreaInsetsを考慮しないとズレる。
        animationOffset = CGPoint(x: itemFrame.center.x, y: itemFrame.center.y - safeAreaInsets.top)
        resetAnimationState()
        
        showAnimation = true
        
        startItemToCartAnimation()
        triggerCartBounceAnimation()
    }

    private func resetAnimationState() {
        animationScale = 1.0
        animationOpacity = 1.0
    }

    private func startItemToCartAnimation() {
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: animationDuration)) {
                self.animationOffset = self.calculateMidPoint()
            }
            
            withAnimation(.easeInOut(duration: animationDuration).delay(midAnimationDelay)) {
                self.animationOffset = self.calculateEndPoint()
                self.animationScale = 0.5
                self.animationOpacity = 0.0
            }
        }
    }

    private func triggerCartBounceAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + midAnimationDelay) {
            self.cartBounce = true
            DispatchQueue.main.asyncAfter(deadline: .now() + cartBounceDuration) {
                self.cartBounce = false
            }
        }
    }

    private func calculateMidPoint() -> CGPoint {
        guard let cartFrame = coordinates[cartID] else { return .zero }
        return CGPoint(x: (animationOffset.x + cartFrame.midX) / 2, y: animationOffset.y - 100)
    }

    private func calculateEndPoint() -> CGPoint {
        guard let cartFrame = coordinates[cartID] else { return .zero }
        return CGPoint(x: cartFrame.midX, y: cartFrame.midY)
    }
}

extension CGRect {
    var center: CGPoint {
        return CGPoint(x: midX, y: midY)
    }
}

public extension UIApplication {
    var keyWindow: UIWindow? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .windows
            .filter(\.isKeyWindow)
            .first
    }
}

extension UIEdgeInsets {
    var edgeInsets: EdgeInsets {
        EdgeInsets(top: top, leading: left, bottom: bottom, trailing: right)
    }
}

private struct SafeAreaInsetsKey: EnvironmentKey {
    static var defaultValue: EdgeInsets {
        UIApplication.shared.keyWindow?.safeAreaInsets.edgeInsets ?? EdgeInsets()
    }
}

public extension EnvironmentValues {
    var safeAreaInsets: EdgeInsets {
        self[SafeAreaInsetsKey.self]
    }
}

// MARK: - Preview

#Preview {
    AddToCartAnimationExample()
}

