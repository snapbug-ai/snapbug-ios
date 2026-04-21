import SwiftUI
import SnapbugDebugFeedback

// MARK: - Snapbug Brand Colors

extension Color {
    static let snapbugPrimary = Color(red: 0/255, green: 110/255, blue: 47/255)        // #006e2f
    static let snapbugPrimaryContainer = Color(red: 34/255, green: 197/255, blue: 94/255) // #22c55e
    static let snapbugSecondary = Color(red: 75/255, green: 65/255, blue: 225/255)      // #4b41e1
    static let snapbugSecondaryContainer = Color(red: 100/255, green: 94/255, blue: 251/255) // #645efb
    static let snapbugTertiary = Color(red: 115/255, green: 46/255, blue: 228/255)     // #732ee4
    static let snapbugSurface = Color(red: 248/255, green: 249/255, blue: 255/255)      // #f8f9ff
    static let snapbugOnSurface = Color(red: 13/255, green: 28/255, blue: 46/255)       // #0d1c2e
    static let snapbugOnPrimary = Color.white
    static let snapbugSurfaceContainerLowest = Color.white                               // #ffffff
    static let snapbugSurfaceContainerLow = Color(red: 239/255, green: 244/255, blue: 255/255) // #eff4ff
    static let snapbugSurfaceContainerHigh = Color(red: 217/255, green: 223/255, blue: 235/255) // #d9dfeb
    static let snapbugSurfaceContainerHighest = Color(red: 205/255, green: 212/255, blue: 224/255) // #cdd4e0
    static let snapbugOutlineVariant = Color(red: 188/255, green: 203/255, blue: 185/255) // #bccbb9
    static let snapbugError = Color(red: 186/255, green: 26/255, blue: 26/255)          // #ba1a1a
}

/// Snapbug brand gradient matching the marketing website (green → white, 135°)
struct SnapbugGradientBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color.snapbugPrimary.opacity(0.08),
                Color.snapbugPrimaryContainer.opacity(0.05),
                Color.snapbugSurface,
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

private struct Product: Identifiable, Hashable {
    let id: Int
    let name: String
    let price: String
    let imageId: Int
    let description: String
}

private struct Review: Identifiable, Hashable {
    let id: Int
    let author: String
    let rating: Int
    let text: String
}

private enum SampleRoute: Hashable {
    case productList
    case productDetail(Int)
    case reviewList(Int)
    case reviewDetail(Int, Int)
    case settings
    case about

    var screenName: String {
        switch self {
        case .productList: return "ProductList"
        case .productDetail: return "ProductDetail"
        case .reviewList: return "ReviewList"
        case .reviewDetail: return "ReviewDetail"
        case .settings: return "Settings"
        case .about: return "About"
        }
    }
}

private let sampleProducts: [Product] = [
    Product(id: 1, name: "Wireless Headphones", price: "$79.99", imageId: 10, description: "Premium noise-cancelling wireless headphones with 30h battery life. Deep bass and crystal-clear highs."),
    Product(id: 2, name: "Smart Watch", price: "$199.99", imageId: 20, description: "Track your fitness, receive notifications, and monitor your health with this sleek smartwatch."),
    Product(id: 3, name: "Portable Speaker", price: "$49.99", imageId: 30, description: "Waterproof Bluetooth speaker with 360-degree sound. Perfect for outdoor adventures."),
    Product(id: 4, name: "USB-C Hub", price: "$34.99", imageId: 40, description: "7-in-1 USB-C hub with HDMI, USB 3.0, SD card reader, and 100W power delivery."),
    Product(id: 5, name: "Mechanical Keyboard", price: "$129.99", imageId: 50, description: "RGB mechanical keyboard with hot-swappable switches and aluminum frame."),
    Product(id: 6, name: "Webcam 4K", price: "$89.99", imageId: 60, description: "Ultra HD webcam with auto-focus, noise-cancelling mic, and privacy shutter."),
    Product(id: 7, name: "Phone Stand", price: "$19.99", imageId: 70, description: "Adjustable aluminum phone/tablet stand. Foldable and portable."),
    Product(id: 8, name: "Power Bank", price: "$39.99", imageId: 80, description: "20000mAh power bank with fast charging. Charges 3 devices simultaneously."),
]

private func reviewsFor(productId: Int) -> [Review] {
    [
        Review(id: 1, author: "Alice", rating: 5, text: "Absolutely love it! Best purchase this year. The quality is outstanding."),
        Review(id: 2, author: "Bob", rating: 4, text: "Good product, fast shipping. Minor issue with packaging but the item itself is perfect."),
        Review(id: 3, author: "Charlie", rating: 3, text: "Decent for the price. Works as described but nothing extraordinary."),
        Review(id: 4, author: "Diana", rating: 5, text: "Exceeded my expectations! Would recommend to everyone."),
        Review(id: 5, author: "Eve", rating: 2, text: "Had some issues with connectivity. Customer support was helpful though."),
        Review(id: 6, author: "Frank", rating: 4, text: "Solid build quality. Using it daily without any problems."),
    ]
}

struct ContentView: View {
    @State private var showDialog = false
    @State private var toastMessage: String?
    @State private var route: SampleRoute = .productList
    @State private var notificationsEnabled = true
    @State private var darkModeEnabled = false
    @State private var analyticsEnabled = true

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                actionButtons
                currentScreen
            }
            .frame(maxWidth: .infinity)
        }
        .background(SnapbugGradientBackground())
        .alert("Test Dialog", isPresented: $showDialog) {
            Button("OK") { }
        } message: {
            Text("FAB should be visible above this dialog")
        }
        .overlay(alignment: .bottom) {
            if let message = toastMessage {
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.snapbugOnSurface.opacity(0.85))
                    .clipShape(Capsule())
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { toastMessage = nil }
                        }
                    }
            }
        }
        .onAppear {
            syncCurrentScreen()
            logAnalytics("screen_view", props: ["screen": route.screenName])
        }
    }

    private var actionButtons: some View {
        FlowLayout(spacing: 6) {
            SampleButton("okhttp test") { runOkHttpTest() }
            SampleButton("ktor test") { runKtorTest() }
            SampleButton("grpc test") { runGrpcTest() }
            SampleButton("crash") { fatalError("my custom crash") }
            SampleButton("show dialog") { showDialog = true }
            SampleButton("send analytics event") { sendAnalyticsEvent() }
            SampleButton("send table event") { sendTableEvent() }
            SampleButton("write SharedPref") { writeSharedPref() }
            SampleButton("Insert dog in DB") { insertDog() }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    @ViewBuilder
    private var currentScreen: some View {
        switch route {
        case .productList:
            ProductListScreen(
                products: sampleProducts,
                onProductClick: { navigate(to: .productDetail($0)) },
                onSettingsClick: { navigate(to: .settings) }
            )
        case .productDetail(let productId):
            ProductDetailScreen(
                product: sampleProducts.first(where: { $0.id == productId }),
                reviewsCount: reviewsFor(productId: productId).count,
                onBack: goBack,
                onReviewsClick: { navigate(to: .reviewList(productId)) },
                onToast: showToast
            )
        case .reviewList(let productId):
            ReviewListScreen(
                reviews: reviewsFor(productId: productId),
                onBack: goBack,
                onReviewClick: { navigate(to: .reviewDetail(productId, $0)) }
            )
        case .reviewDetail(let productId, let reviewId):
            ReviewDetailScreen(
                product: sampleProducts.first(where: { $0.id == productId }),
                review: reviewsFor(productId: productId).first(where: { $0.id == reviewId }),
                onBack: goBack
            )
        case .settings:
            SettingsScreen(
                notificationsEnabled: $notificationsEnabled,
                darkModeEnabled: $darkModeEnabled,
                analyticsEnabled: $analyticsEnabled,
                onBack: goBack,
                onAboutClick: { navigate(to: .about) }
            )
        case .about:
            AboutScreen(onBack: goBack)
        }
    }

    private func navigate(to newRoute: SampleRoute) {
        route = newRoute
        syncCurrentScreen()
        logAnalytics("screen_view", props: ["screen": newRoute.screenName])
    }

    private func goBack() {
        let from = route.screenName
        switch route {
        case .reviewDetail(let productId, _):
            route = .reviewList(productId)
        case .reviewList(let productId):
            route = .productDetail(productId)
        case .productDetail:
            route = .productList
        case .about:
            route = .settings
        case .settings:
            route = .productList
        case .productList:
            route = .productList
        }
        syncCurrentScreen()
        logAnalytics("navigate_back", props: ["from": from, "to": route.screenName])
    }

    private func syncCurrentScreen() {
        SampleAppState.shared.currentScreen = route.screenName
    }

    private func runOkHttpTest() {
        Task {
            do {
                let url = URL(string: "https://jsonplaceholder.typicode.com/todos/1")!
                let (_, response) = try await URLSession.shared.data(from: url)
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                showToast("okhttp test: HTTP \(statusCode)")
            } catch {
                showToast("okhttp error: \(error.localizedDescription)")
            }
        }
    }

    private func runKtorTest() {
        Task {
            do {
                var request = URLRequest(url: URL(string: "https://httpbin.org/gzip")!)
                request.addValue("gzip", forHTTPHeaderField: "Accept-Encoding")
                let (_, response) = try await URLSession.shared.data(for: request)
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                showToast("ktor test: HTTP \(statusCode)")
            } catch {
                showToast("ktor error: \(error.localizedDescription)")
            }
        }
    }

    private func runGrpcTest() {
        logAnalytics("grpc_test_tap")
        showToast("grpc test is not wired on iOS sample yet")
    }

    private func sendAnalyticsEvent() {
        logAnalytics("clicked user", props: ["userId": "1024", "username": "florent", "index": "3"])
        logAnalytics("opened profile", props: ["userId": "2048", "username": "kevin", "age": "34"])
        showToast("Analytics event sent")
    }

    private func sendTableEvent() {
        let value = Int.random(in: 0..<1000)
        showToast("Table event sent: event_\(value)")
    }

    private func writeSharedPref() {
        let key = "test_key_\(Int.random(in: 0..<100))"
        UserDefaults.standard.set("value_\(Date().timeIntervalSince1970)", forKey: key)
        UserDefaults.standard.set(Int.random(in: 0..<1000), forKey: "counter")
        UserDefaults.standard.set(Bool.random(), forKey: "enabled")
        showToast("SharedPref written")
    }

    private func insertDog() {
        showToast("Dog inserted")
    }

    private func showToast(_ message: String) {
        withAnimation { toastMessage = message }
    }

    private func logAnalytics(_ eventName: String, props: [String: String] = [:]) {
        #if DEBUG
        SnapbugAnalyticsHelper.shared.sendEvent(
            trackerName: "firebase",
            eventName: eventName,
            properties: props
        )
        #endif
    }
}

private struct ProductListScreen: View {
    let products: [Product]
    let onProductClick: (Int) -> Void
    let onSettingsClick: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Products")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color.snapbugOnSurface)
                Spacer()
                Button(action: onSettingsClick) {
                    Image(systemName: "gearshape.fill")
                        .font(.title3)
                        .foregroundStyle(Color.snapbugPrimary)
                }
            }
            .padding(16)

            LazyVStack(spacing: 8) {
                ForEach(products) { product in
                    Button(action: { onProductClick(product.id) }) {
                        HStack(spacing: 12) {
                            AsyncImage(url: URL(string: "https://picsum.photos/id/\(product.imageId)/200/200")) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                default:
                                    Color(.systemGray4)
                                }
                            }
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(product.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                    .multilineTextAlignment(.leading)
                                Text(product.price)
                                    .font(.body)
                                    .foregroundStyle(Color.snapbugPrimary)
                            }
                            Spacer()
                        }
                        .padding(12)
                        .background(.background)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }
}

private struct ProductDetailScreen: View {
    let product: Product?
    let reviewsCount: Int
    let onBack: () -> Void
    let onReviewsClick: () -> Void
    let onToast: (String) -> Void

    var body: some View {
        if let product {
            VStack(alignment: .leading, spacing: 0) {
                BackHeader(title: product.name, onBack: onBack)

                AsyncImage(url: URL(string: "https://picsum.photos/id/\(product.imageId)/800/400")) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        Color(.systemGray4)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .clipped()

                VStack(alignment: .leading, spacing: 12) {
                    Text(product.price)
                        .font(.title2.bold())
                        .foregroundStyle(Color.snapbugPrimary)
                    Text(product.description)
                        .font(.body)

                    HStack(spacing: 8) {
                        Button("Add to Cart") {
                            SnapbugAnalyticsHelper.shared.sendEvent(
                                trackerName: "firebase",
                                eventName: "add_to_cart",
                                properties: ["product_id": "\(product.id)", "product": product.name, "price": product.price]
                            )
                            onToast("\(product.name) added to cart")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.snapbugPrimary)

                        Button("Buy Now") {
                            SnapbugAnalyticsHelper.shared.sendEvent(
                                trackerName: "firebase",
                                eventName: "buy_now",
                                properties: ["product_id": "\(product.id)", "product": product.name, "price": product.price]
                            )
                        }
                        .buttonStyle(.bordered)
                    }

                    Button(action: onReviewsClick) {
                        HStack {
                            Image(systemName: "star.fill")
                            Text("Reviews (\(reviewsCount))")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.snapbugSecondary)
                }
                .padding(16)
            }
        }
    }
}

private struct ReviewListScreen: View {
    let reviews: [Review]
    let onBack: () -> Void
    let onReviewClick: (Int) -> Void

    var body: some View {
        VStack(spacing: 0) {
            BackHeader(title: "Reviews", onBack: onBack)

            LazyVStack(spacing: 8) {
                ForEach(reviews) { review in
                    Button(action: { onReviewClick(review.id) }) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(review.author)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Spacer()
                                StarsView(rating: review.rating, size: 16)
                            }
                            Text(review.text)
                                .font(.body)
                                .foregroundStyle(.primary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(.background)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
    }
}

private struct ReviewDetailScreen: View {
    let product: Product?
    let review: Review?
    let onBack: () -> Void

    var body: some View {
        if let review {
            VStack(alignment: .leading, spacing: 0) {
                BackHeader(title: "Review by \(review.author)", onBack: onBack)

                VStack(alignment: .leading, spacing: 12) {
                    if let product {
                        Text("Product: \(product.name)")
                            .foregroundStyle(.secondary)
                    }

                    StarsView(rating: review.rating, size: 24)
                    Text(review.text)
                        .font(.body)

                    Spacer()
                        .frame(height: 16)

                    Text("Was this review helpful?")
                        .font(.subheadline)

                    HStack(spacing: 8) {
                        Button("Yes") {
                            SnapbugAnalyticsHelper.shared.sendEvent(trackerName: "firebase", eventName: "review_helpful", properties: ["review_id": "\(review.id)", "helpful": "yes"])
                        }
                        .buttonStyle(.bordered)

                        Button("No") {
                            SnapbugAnalyticsHelper.shared.sendEvent(trackerName: "firebase", eventName: "review_helpful", properties: ["review_id": "\(review.id)", "helpful": "no"])
                        }
                        .buttonStyle(.bordered)

                        Button("Report") {
                            SnapbugAnalyticsHelper.shared.sendEvent(trackerName: "firebase", eventName: "review_report", properties: ["review_id": "\(review.id)"])
                        }
                    }
                }
                .padding(16)
            }
        }
    }
}

private struct SettingsScreen: View {
    @Binding var notificationsEnabled: Bool
    @Binding var darkModeEnabled: Bool
    @Binding var analyticsEnabled: Bool
    let onBack: () -> Void
    let onAboutClick: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            BackHeader(title: "Settings", onBack: onBack)

            VStack(spacing: 4) {
                SettingsToggle(label: "Push Notifications", isOn: $notificationsEnabled, settingKey: "notifications")
                SettingsToggle(label: "Dark Mode", isOn: $darkModeEnabled, settingKey: "dark_mode")
                SettingsToggle(label: "Analytics", isOn: $analyticsEnabled, settingKey: "analytics")

                Spacer()
                    .frame(height: 16)

                Button("Clear Cache") {
                    SnapbugAnalyticsHelper.shared.sendEvent(trackerName: "firebase", eventName: "button_tap", properties: ["button": "clear_cache"])
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.snapbugPrimary)
                .frame(maxWidth: .infinity)

                Button("Export Data") {
                    SnapbugAnalyticsHelper.shared.sendEvent(trackerName: "firebase", eventName: "button_tap", properties: ["button": "export_data"])
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)

                Button("About", action: onAboutClick)
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)

                Spacer()
                    .frame(height: 16)

                Button("Log Out") {
                    SnapbugAnalyticsHelper.shared.sendEvent(trackerName: "firebase", eventName: "button_tap", properties: ["button": "log_out"])
                }
                .foregroundStyle(.red)
            }
            .padding(16)
        }
    }
}

private struct AboutScreen: View {
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            BackHeader(title: "About", onBack: onBack)

            VStack(spacing: 12) {
                Spacer()
                    .frame(height: 32)
                Text("Snapbug Sample")
                    .font(.largeTitle.bold())
                Text("Version 1.0.0")
                    .font(.body)
                Spacer()
                    .frame(height: 8)
                Text("A sample app to demonstrate Snapbug SDK capabilities.")
                    .multilineTextAlignment(.center)
                Text("Built with SwiftUI")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
                    .frame(height: 24)

                Button("Privacy Policy") {
                    SnapbugAnalyticsHelper.shared.sendEvent(trackerName: "firebase", eventName: "button_tap", properties: ["button": "privacy_policy"])
                }
                .buttonStyle(.bordered)

                Button("Terms of Service") {
                    SnapbugAnalyticsHelper.shared.sendEvent(trackerName: "firebase", eventName: "button_tap", properties: ["button": "terms_of_service"])
                }
                .buttonStyle(.bordered)

                Button("Open Source Licenses") {
                    SnapbugAnalyticsHelper.shared.sendEvent(trackerName: "firebase", eventName: "button_tap", properties: ["button": "open_source_licenses"])
                }
                .buttonStyle(.bordered)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
        }
    }
}

private struct BackHeader: View {
    let title: String
    let onBack: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .foregroundStyle(Color.snapbugPrimary)
            }
            Text(title)
                .font(.title2.bold())
                .lineLimit(1)
            Spacer()
        }
        .padding(8)
    }
}

private struct SettingsToggle: View {
    let label: String
    @Binding var isOn: Bool
    let settingKey: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Toggle("", isOn: Binding(
                get: { isOn },
                set: { newValue in
                    isOn = newValue
                    SnapbugAnalyticsHelper.shared.sendEvent(
                        trackerName: "firebase",
                        eventName: "setting_changed",
                        properties: ["setting": settingKey, "value": "\(newValue)"]
                    )
                }
            ))
            .labelsHidden()
        }
        .padding(.vertical, 8)
    }
}

private struct StarsView: View {
    let rating: Int
    let size: CGFloat

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { index in
                Image(systemName: index < rating ? "star.fill" : "star")
                    .foregroundStyle(index < rating ? .yellow : .gray)
                    .font(.system(size: size))
            }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            totalHeight = y + rowHeight
        }

        return (CGSize(width: maxWidth, height: totalHeight), positions)
    }
}

struct SampleButton: View {
    let title: String
    let action: () -> Void

    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.callout)
                .fontWeight(.medium)
                .foregroundStyle(Color.snapbugOnPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: [Color.snapbugPrimary, Color.snapbugPrimaryContainer],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

#Preview {
    ContentView()
}
