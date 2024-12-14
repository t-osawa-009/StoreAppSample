import SwiftUI

// MARK: - Product Model

struct Product: Identifiable {
    let id: UUID
    let name: String
    let price: String
}

struct ContentView: View {
    @State private var coordinates: [UUID: CGRect] = [:]
    @State private var showAnimation: Bool = false
    @State private var animationOffset: CGPoint = .zero
    @State private var animationScale: CGFloat = 1.0
    @State private var animationOpacity: Double = 1.0
    @State private var cartBounce: Bool = false
    @State private var cartItemCount: Int = 0
    @State private var itemCountScale: CGFloat = 1.0  // バッジのスケール
    @State private var itemCountOpacity: Double = 1.0  // バッジの透明度
    
    private let products = [
        Product(id: UUID(), name: "Product 1", price: "$10"),
        Product(id: UUID(), name: "Product 2", price: "$20"),
        Product(id: UUID(), name: "Product 3", price: "$30")
    ]
    @Environment(\.safeAreaInsets) var safeAreaInsets
    private let cartID = UUID()
    
    var body: some View {
        ZStack {
            NavigationStack {
                VStack(spacing: 16) {
                    ScrollView {
                        ForEach(products) { product in
                            productItemView(product: product)
                        }
                    }
                    
                    Spacer()
                    
                    HStack {
                        Spacer()
                        cartView()
                    }.padding()
                }
                .onPreferenceChange(CoordinatePreferenceKey.self) { preferences in
                    self.coordinates = preferences
                }.navigationTitle("Product List")
                    .toolbarTitleDisplayMode(.large)
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
    
    private func productItemView(product: Product) -> some View {
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
    
    private func cartView() -> some View {
        Button(action: {
            
        }, label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "cart.fill")
                    .font(.largeTitle)
                    .foregroundStyle(Color.white)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(8)
                    .scaleEffect(cartBounce ? 1.2 : 1.0)
                    .animation(.interpolatingSpring(stiffness: 300, damping: 10).delay(0.7), value: cartBounce)
                    .reportCoordinates(using: cartID)
                
                if cartItemCount > 0 {
                    Text("\(cartItemCount)")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.red)
                        .clipShape(Circle())
                        .scaleEffect(itemCountScale)
                        .opacity(itemCountOpacity)
                        .offset(x: 12, y: -12)
                }
            }
        })
    }
    
    private let animationDuration: Double = 0.7
    private let cartBounceDuration: Double = 0.3
    private let midAnimationDelay: Double = 0.7

    private func triggerAddToCartAnimation(for productID: UUID) {
        guard let itemFrame = coordinates[productID] else { return }
        
        // safeAreaInsetsを考慮しないとズレる。
        animationOffset = CGPoint(x: itemFrame.midX, y: itemFrame.midY - safeAreaInsets.top)
        resetAnimationState()
        
        showAnimation = true
        
        startItemToCartAnimation()
        triggerCartBounceAnimation {
            animateItemCountIncrement()
        }
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

    private func triggerCartBounceAnimation(completion: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + midAnimationDelay) {
            self.cartBounce = true
            DispatchQueue.main.asyncAfter(deadline: .now() + cartBounceDuration) {
                self.cartBounce = false
                completion()
            }
        }
    }
    
    private func animateItemCountIncrement() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            itemCountScale = 1.3  // スケールアップ
            
            withAnimation(.easeInOut(duration: 0.3)) {
                cartItemCount += 1
                itemCountScale = 1.0  // スケールダウン
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

// MARK: - Preview

#Preview {
    ContentView()
}

