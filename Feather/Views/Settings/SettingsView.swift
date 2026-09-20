//
//  SettingsView.swift
//  Aurora
//

import SwiftUI
import NimbleViews
import UIKit
import Darwin
import IDeviceSwift
import AltSourceKit

struct SettingsView: View {
    @AppStorage("feather.selectedCert") private var storedSelectedCert: Int = 0
    @AppStorage("Feather.userTintColor") private var tintHex: String = "#848ef9"
    @AppStorage("aurora.language") private var language = "en"
    @AppStorage("aurora.hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @State private var currentIcon: String? = UIApplication.shared.alternateIconName
    @State private var showingResetOnboarding = false

    @FetchRequest(
        entity: CertificatePair.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)],
        animation: .snappy
    ) private var certificates: FetchedResults<CertificatePair>

    private let donationsURL = "https://github.com/sponsors/khcrysalis"
    private let githubURL = "https://github.com/sideload-kor/Aurora"

    private var selectedCertificate: CertificatePair? {
        guard storedSelectedCert >= 0, storedSelectedCert < certificates.count else { return nil }
        return certificates[storedSelectedCert]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 22) {
                    hero

                    settingsSection(.localized("General")) {
                        NavigationLink {
                            AuroraLanguageSettingsView(language: $language)
                        } label: {
                            AuroraSettingsRow(
                                icon: "globe",
                                color: .orange,
                                title: .localized("Language"),
                                value: languageName
                            )
                        }

                        NavigationLink(destination: AppearanceView()) {
                            AuroraSettingsRow(
                                icon: "paintbrush",
                                color: .purple,
                                title: .localized("Appearance")
                            )
                        }

                        NavigationLink(destination: AppIconView(currentIcon: $currentIcon)) {
                            AuroraSettingsRow(
                                icon: "app.badge",
                                color: .pink,
                                title: .localized("App Icon")
                            )
                        }
                    }

                    settingsSection(.localized("Signing")) {
                        NavigationLink(destination: CertificatesView()) {
                            AuroraSettingsRow(
                                icon: "checkmark.seal.fill",
                                color: .green,
                                title: .localized("Certificates"),
                                value: selectedCertificate == nil
                                    ? .localized("Not configured")
                                    : .localized("Ready")
                            )
                        }

                        NavigationLink(destination: ConfigurationView()) {
                            AuroraSettingsRow(
                                icon: "signature",
                                color: .blue,
                                title: .localized("Signing Options")
                            )
                        }

                        NavigationLink(destination: InstallationView()) {
                            AuroraSettingsRow(
                                icon: "arrow.down.circle.fill",
                                color: .indigo,
                                title: .localized("Installation")
                            )
                        }
                    }

                    settingsSection(.localized("Sources & Storage")) {
                        NavigationLink(destination: AuroraRepositoriesSettingsView()) {
                            AuroraSettingsRow(
                                icon: "globe.desk",
                                color: .orange,
                                title: .localized("Repositories"),
                                value: .localized("Manage")
                            )
                        }

                        NavigationLink(destination: ArchiveView()) {
                            AuroraSettingsRow(
                                icon: "archivebox.fill",
                                color: .teal,
                                title: .localized("Archive & Compression")
                            )
                        }

                        documentsButton(
                            title: .localized("Open Documents"),
                            icon: "folder.fill",
                            url: URL.documentsDirectory.toSharedDocumentsURL()
                        )
                    }

                    settingsSection(.localized("Support")) {
                        NavigationLink(destination: AboutView()) {
                            HStack(spacing: 13) {
                                FRAppIconView(size: 34)
                                Text(verbatim: .localized("About %@", arguments: Bundle.main.name))
                                    .font(.body.weight(.medium))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.horizontal, 15)
                            .padding(.vertical, 12)
                        }

                        Button {
                            UIApplication.open(donationsURL)
                        } label: {
                            AuroraSettingsRow(
                                icon: "heart.fill",
                                color: .pink,
                                title: .localized("Donations"),
                                value: .localized("Support Aurora")
                            )
                        }

                        Button {
                            submitFeedback()
                        } label: {
                            AuroraSettingsRow(
                                icon: "exclamationmark.bubble.fill",
                                color: .orange,
                                title: .localized("Submit Feedback")
                            )
                        }

                        Button {
                            UIApplication.open(githubURL)
                        } label: {
                            AuroraSettingsRow(
                                icon: "chevron.left.forwardslash.chevron.right",
                                color: .gray,
                                title: .localized("GitHub Repository")
                            )
                        }
                    }

                    settingsSection(.localized("Advanced")) {
                        documentsButton(
                            title: .localized("Open Archives"),
                            icon: "archivebox",
                            url: FileManager.default.archives.toSharedDocumentsURL()
                        )

                        documentsButton(
                            title: .localized("Open Certificates"),
                            icon: "checkmark.seal",
                            url: FileManager.default.certificates.toSharedDocumentsURL()
                        )

                        Button {
                            showingResetOnboarding = true
                        } label: {
                            AuroraSettingsRow(
                                icon: "wand.and.stars",
                                color: .orange,
                                title: .localized("Show Welcome Again")
                            )
                        }

                        NavigationLink(destination: ResetView()) {
                            AuroraSettingsRow(
                                icon: "trash.fill",
                                color: .red,
                                title: .localized("Reset")
                            )
                        }
                    }

                    Text(.localized("Aurora keeps everyday actions simple while advanced signing and storage tools remain one tap away."))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                        .padding(.bottom, 6)
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(.localized("Settings"))
            .navigationBarTitleDisplayMode(.large)
            .tint(Color(hex: tintHex))
            .alert(.localized("Show Welcome Again"), isPresented: $showingResetOnboarding) {
                Button(.localized("Cancel"), role: .cancel) { }
                Button(.localized("Continue")) {
                    hasCompletedOnboarding = false
                }
            } message: {
                Text(.localized("Aurora will show the welcome screens right away."))
            }
        }
        .environment(\.locale, Locale(identifier: language))
    }

    private var languageName: String {
        switch language {
        case "ko": return "한국어"
        case "zh-Hans": return "简体中文"
        case "ja": return "日本語"
        case "es": return "Español"
        default: return "English"
        }
    }

    private var hero: some View {
        HStack(spacing: 15) {
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.orange, .pink.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 23, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 58, height: 58)

            VStack(alignment: .leading, spacing: 4) {
                Text(.localized("Customize Aurora"))
                    .font(.title3.weight(.bold))
                Text(.localized("Everything technical, in one quiet place."))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .auroraSettingsGlass(cornerRadius: 25)
    }

    @ViewBuilder
    private func settingsSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                content()
            }
            .clipShape(RoundedRectangle(cornerRadius: 21, style: .continuous))
            .auroraSettingsGlass(cornerRadius: 21)
        }
    }

    @ViewBuilder
    private func documentsButton(title: String, icon: String, url: URL?) -> some View {
        if let url {
            Button {
                UIApplication.open(url)
            } label: {
                AuroraSettingsRow(icon: icon, color: .teal, title: title)
            }
        }
    }

    private func submitFeedback() {
        let bugAction = UIAlertAction(title: .localized("Bug Report"), style: .default) { _ in
            UIApplication.open(_makeGitHubIssueURL(url: githubURL))
        }
        let otherAction = UIAlertAction(title: .localized("Other"), style: .default) { _ in
            UIApplication.open(URL(string: "\(githubURL)/issues/new/choose")!)
        }

        UIAlertController.showAlertWithCancel(
            title: .localized("Submit Feedback"),
            message: nil,
            actions: [bugAction, otherAction]
        )
    }

    private func _makeGitHubIssueURL(url: String) -> String {
        var configurationSection = "### App Configuration:\n"

        switch UserDefaults.standard.integer(forKey: "Feather.installationMethod") {
        case 0:
            let serverMethod = UserDefaults.standard.integer(forKey: "Feather.serverMethod")
            let ipFix = UserDefaults.standard.bool(forKey: "Feather.ipFix")
            let serverType = (serverMethod == 0) ? "Fully Local" : "Semi Local"
            configurationSection += "- Install method: `Server`\n"
            configurationSection += "  - Server type: `\(serverType)`\n"
            configurationSection += "  - IP Fix: `\(ipFix)`\n"
        case 1:
            let pairingPath = HeartbeatManager.pairingFile()
            let pairingExists = FileManager.default.fileExists(atPath: pairingPath)
            configurationSection += "- Install method: `idevice`\n"
            configurationSection += "  - Pairing file: \(pairingExists ? "`Present`" : "`Not Present`")\n"
        default:
            configurationSection += "- Install method: `Unknown`\n"
        }

        let body = """
        ### Device Information
        - Device: `\(MobileGestalt().getStringForName("PhysicalHardwareNameString") ?? "Unknown")`
        - iOS Version: `\(UIDevice.current.systemVersion)`
        - App Version: `\(Bundle.main.version)`

        \(configurationSection)

        ### Issue Description
        <!-- Describe your issue here -->

        ### Steps to Reproduce
        1.
        2.
        3.

        ### Expected Behavior

        ### Actual Behavior
        """

        let encodedTitle = "[Bug] replace this with a descriptive title"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return "\(url)/issues/new?template=bug.yml&title=\(encodedTitle)&body=\(encodedBody)"
    }
}

private struct AuroraSettingsRow: View {
    let icon: String
    let color: Color
    let title: String
    var value: String?

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 35, height: 35)
                .background(color.gradient, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            Text(title)
                .font(.body.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(1)

            Spacer(minLength: 8)

            if let value, !value.isEmpty {
                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 11)
        .contentShape(Rectangle())
    }
}

private struct AuroraLanguageSettingsView: View {
    @Binding var language: String

    private let languages: [(String, String, String)] = [
        ("en", "🇺🇸", "English"),
        ("ko", "🇰🇷", "한국어"),
        ("zh-Hans", "🇨🇳", "简体中文"),
        ("ja", "🇯🇵", "日本語"),
        ("es", "🇪🇸", "Español")
    ]

    var body: some View {
        List {
            Section {
                ForEach(languages, id: \.0) { item in
                    Button {
                        language = item.0
                    } label: {
                        HStack(spacing: 12) {
                            Text(item.1)
                                .font(.title3)
                            Text(item.2)
                                .font(.body.weight(.medium))
                            Spacer()
                            if language == item.0 {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.orange)
                                    .font(.title3)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                }
            } footer: {
                Text(.localized("Your language is also available during onboarding."))
            }
        }
        .navigationTitle(.localized("Language"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct AuroraRepositoriesSettingsView: View {
    @StateObject private var viewModel = SourcesViewModel.shared
    @State private var showAddSource = false

    @FetchRequest(
        entity: AltSource.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \AltSource.name, ascending: true)],
        animation: .snappy
    ) private var sources: FetchedResults<AltSource>

    var body: some View {
        List {
            Section {
                Button {
                    showAddSource = true
                } label: {
                    Label(.localized("Add Source"), systemImage: "plus.circle.fill")
                }
            }

            Section(.localized("Repositories")) {
                if sources.isEmpty {
                    Text(.localized("No Repositories"))
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sources) { source in
                        HStack(spacing: 12) {
                            Image(systemName: "globe.desk.fill")
                                .foregroundStyle(.orange)
                                .frame(width: 28)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(source.name ?? .localized("Unknown"))
                                    .font(.body.weight(.semibold))
                                Text(source.sourceURL?.absoluteString ?? "")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                        }
                        .swipeActions {
                            Button(.localized("Delete"), systemImage: "trash", role: .destructive) {
                                Storage.shared.deleteSource(for: source)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(.localized("Repositories"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddSource = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSource) {
            SourcesAddView()
                .presentationDetents([.medium, .large])
        }
    }
}

private extension View {
    @ViewBuilder
    func auroraSettingsGlass(cornerRadius: CGFloat) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(
                .regular.tint(.orange.opacity(0.08)),
                in: .rect(cornerRadius: cornerRadius)
            )
        } else {
            self
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color.orange.opacity(0.12), lineWidth: 0.8)
                }
        }
    }
}
