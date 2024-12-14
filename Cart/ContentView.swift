import SwiftUI

// MARK: - Product Model

struct Product: Identifiable {
    let id: UUID
    let name: String
    let price: String
}

struct CircleAnimation: Identifiable {
    let id: UUID
    var position: CGPoint
    var scale: CGFloat
    var opacity: Double
    let duration: Double
    
    init(id: UUID, initialPosition: CGPoint, finalPosition: CGPoint, duration: Double, scale: CGFloat, opacity: Double) {
        self.id = id
        self.position = initialPosition
        self.scale = scale
        self.opacity = opacity
        self.duration = duration
    }
}

struct ContentView: View {
    @State private var coordinates: [UUID: CGRect] = [:]
    @State private var animations: [CircleAnimation] = []
    @State private var cartBounce: Bool = false
    @State private var cartItemCount: Int = 0
    @State private var itemCountScale: CGFloat = 1.0
    @State private var itemCountOpacity: Double = 1.0
    @State private var animationOffset: CGPoint = .zero
    
    private let products = [
        Product(id: UUID(), name: "Product 1", price: "$10"),
        Product(id: UUID(), name: "Product 2", price: "$20"),
        Product(id: UUID(), name: "Product 3", price: "$30"),
        Product(id: UUID(), name: "Product 4", price: "$40"),
        Product(id: UUID(), name: "Product 5", price: "$50"),
        Product(id: UUID(), name: "Product 6", price: "$60"),
        Product(id: UUID(), name: "Product 7", price: "$70"),
        Product(id: UUID(), name: "Product 8", price: "$80"),
        Product(id: UUID(), name: "Product 9", price: "$90"),
        Product(id: UUID(), name: "Product 10", price: "$100"),
        Product(id: UUID(), name: "Product 11", price: "$110"),
        Product(id: UUID(), name: "Product 12", price: "$120")
    ]
    
    @Environment(\.safeAreaInsets) var safeAreaInsets
    private let cartID = UUID()
    
    var body: some View {
        ZStack {
            NavigationStack {
                VStack(spacing: 16) {
                    ZStack {
                        ScrollView {
                            ForEach(products) { product in
                                productItemView(product: product)
                            }
                            Color.clear.padding(.bottom, 100)
                        }
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                cartView()
                            }.padding()
                        }
                    }
                }
                .onPreferenceChange(CoordinatePreferenceKey.self) { preferences in
                    self.coordinates = preferences
                }.navigationTitle("Product List")
                    .toolbarTitleDisplayMode(.large)
            }
            
            // Display all Circle animations
            ForEach(animations) { animation in
                Circle()
                    .fill(Color.red)
                    .frame(width: 30, height: 30)
                    .scaleEffect(animation.scale)
                    .opacity(animation.opacity)
                    .position(x: animation.position.x, y: animation.position.y)
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
            // Cart button action
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
        
        // Set the animation offset based on the item's position
        animationOffset = CGPoint(x: itemFrame.midX - safeAreaInsets.leading,
                                  y: itemFrame.midY - safeAreaInsets.top)
        
        // Create a new animation for this tap
        let newAnimation = CircleAnimation(
            id: UUID(),
            initialPosition: animationOffset, // Use animationOffset here
            finalPosition: calculateEndPoint(),
            duration: animationDuration,
            scale: 1.0,
            opacity: 1.0
        )
        
        animations.append(newAnimation)
        startItemToCartAnimation(for: newAnimation)
        
        // Trigger cart bounce and item count increment
        triggerCartBounceAnimation {
            animateItemCountIncrement()
        }
    }
    
    private func startItemToCartAnimation(for animation: CircleAnimation) {
        // Find the index of the animation in the animations array
        guard let index = animations.firstIndex(where: { $0.id == animation.id }) else { return }
        
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: animation.duration)) {
                // Move the animation to the mid-point
                animations[index].position = self.calculateMidPoint()
            }
            
            withAnimation(.easeInOut(duration: animation.duration).delay(midAnimationDelay)) {
                // Move the animation to the final position
                animations[index].position = self.calculateEndPoint()
                animations[index].scale = 0.5
                animations[index].opacity = 0.0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + animation.duration + midAnimationDelay) {
            if let index = self.animations.firstIndex(where: { $0.id == animation.id }) {
                self.animations.remove(at: index)
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
            itemCountScale = 1.3
            withAnimation(.easeInOut(duration: 0.3)) {
                cartItemCount += 1
                itemCountScale = 1.0
            }
        }
    }
    
    private func calculateEndPoint() -> CGPoint {
        guard let cartFrame = coordinates[cartID] else { return .zero }
        return CGPoint(x: cartFrame.midX - safeAreaInsets.leading,
                       y: cartFrame.midY - safeAreaInsets.top)
    }

    private func calculateMidPoint() -> CGPoint {
        guard let cartFrame = coordinates[cartID] else { return .zero }
        return CGPoint(x: (animationOffset.x + cartFrame.midX) / 2,
                       y: animationOffset.y - 100)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}

