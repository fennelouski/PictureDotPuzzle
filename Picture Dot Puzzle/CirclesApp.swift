import SwiftUI
import UIKit

@objc(CirclesSceneDelegate)
final class CirclesSceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: scene)
        window.rootViewController = UIHostingController(rootView: CirclesHome())
        self.window = window
        window.makeKeyAndVisible()
    }
}

private struct CirclesHome: View {
    private enum Destination: String, Identifiable {
        case artwork, photo, settings
        var id: String { rawValue }
    }
    @State private var destination: Destination?
    @AppStorage("CirclesAppearance") private var appearance = "system"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Image(systemName: "circle.grid.3x3.fill")
                        .font(.system(size: 64)).foregroundStyle(.tint)
                        .accessibilityHidden(true)
                    Text("Reveal a photo, one circle at a time.")
                        .font(.largeTitle.bold())
                    Text("Touch and drag across the canvas to divide the circles. Adjust their shape, watch an automatic reveal, or share your artwork.")
                        .font(.body).foregroundStyle(.secondary)
                    Button { destination = .photo } label: {
                        Label("Choose a photo", systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent).controlSize(.large)
                    Button { destination = .artwork } label: {
                        Label("Open canvas", systemImage: "circle.hexagongrid")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered).controlSize(.large)
                    Text("The canvas starts with a sample image. Your selected photo stays in memory while the app is open. Returning home resets the canvas. Use Share to keep your artwork.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                .padding(24).frame(maxWidth: 620, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("Circles to the Max")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { destination = .settings } label: { Label("Settings", systemImage: "gearshape") }
                }
            }
            .fullScreenCover(item: $destination) { selection in
                if selection == .settings { CirclesSettings() }
                else { ArtworkScreen(choosePhoto: selection == .photo) }
            }
        }
        .preferredColorScheme(appearance == "dark" ? .dark : appearance == "light" ? .light : nil)
    }
}

private struct ArtworkScreen: View {
    @Environment(\.dismiss) private var dismiss
    let choosePhoto: Bool
    @State private var confirmingReturnHome = false

    var body: some View {
        NavigationStack {
            OriginalCanvas(choosePhoto: choosePhoto)
                .confirmationDialog("Return home?", isPresented: $confirmingReturnHome, titleVisibility: .visible) {
                    Button("Return home", role: .destructive) { dismiss() }
                } message: {
                    Text("Your current canvas will be cleared. Share it first if you want to keep it.")
                }
                .navigationTitle("Canvas")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Home") { confirmingReturnHome = true } }
                }
        }
    }
}

private struct OriginalCanvas: UIViewControllerRepresentable {
    let choosePhoto: Bool

    func makeUIViewController(context: Context) -> ViewController {
        let controller = ViewController()
        controller.openPhotoPickerOnAppearance = choosePhoto
        return controller
    }

    func updateUIViewController(_ controller: ViewController, context: Context) {}
    static func dismantleUIViewController(_ controller: ViewController, coordinator: ()) {
        controller.stopArtwork()
    }
}

private struct CirclesSettings: View {
    private var softwareNotices: String {
        guard let url = Bundle.main.url(forResource: "ThirdPartyNotices", withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8) else { return "Software notices could not be opened." }
        return text
    }
    @Environment(\.dismiss) private var dismiss
    @AppStorage("CirclesAppearance") private var appearance = "system"
    @AppStorage("Animation Duration K£y") private var animationDuration = 0.35
    @AppStorage("Automation Duration K£y") private var automationDuration = 6.0

    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Picker("Color scheme", selection: $appearance) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                }
                Section("Animation") {
                    Slider(value: $animationDuration, in: 0.05...1, step: 0.05) {
                        Text("Circle animation")
                    }
                    Text("Circle animation: \(animationDuration, specifier: "%.2f") seconds")
                    Slider(value: $automationDuration, in: 2...20, step: 1) {
                        Text("Automatic reveal")
                    }
                    Text("Automatic reveal: \(automationDuration, specifier: "%.0f") seconds before final detail")
                    Text("The canvas respects the device's Reduce Motion setting.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("Your photos") {
                    Text("Choose a photo with Apple's photo picker. Only your selection is opened. Artwork is temporary until you export it with Share; the app does not upload your photos.")
                    Link("Privacy policy", destination: URL(string: "https://nathanfennel.com/circles-to-the-max/privacy.html")!)
                    Link("Support", destination: URL(string: "https://nathanfennel.com/contact")!)
                }
                Section("About") {
                    NavigationLink("Software notices") {
                        ScrollView {
                            Text(softwareNotices).font(.footnote).padding().textSelection(.enabled)
                        }.navigationTitle("Software notices")
                    }
                    LabeledContent("Version", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")
                    Text("Original photo-to-circle canvas by Nathan Fennel. The renderer and toolbar are preserved in this release.")
                        .font(.footnote)
                }
            }
            .navigationTitle("Settings")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .onChange(of: animationDuration) { PDPDataManager.shared().animationDuration = $0 }
            .onChange(of: automationDuration) { PDPDataManager.shared().automationDuration = $0 }
        }
        .preferredColorScheme(appearance == "dark" ? .dark : appearance == "light" ? .light : nil)
    }
}
