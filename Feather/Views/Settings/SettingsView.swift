//
//  SettingsView.swift
//  Aurora
//

import SwiftUI
import NimbleViews
import UIKit
import Darwin
import IDeviceSwift

struct SettingsView: View {
    @AppStorage("feather.selectedCert") private var storedSelectedCert: Int = 0
    @AppStorage("aurora.language") private var language = "en"
    @State private var currentIcon: String? = UIApplication.shared.alternateIconName

    @FetchRequest(
        entity: CertificatePair.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \.CertificatePair.date, ascending: false)],
        animation: .snappy
    ) private var certificates: FetchedResults<CertificatePair>

    private var selectedCertificate: CertificatePair? {
        guard storedSelectedCert >= 0, storedSelectedCert < certificates.count else { return nil }
        return certificates[storedSelectedCert]
    }

    private let donationsUrl = "https://github.com/sponsors/claration"
    private let githubUrl = "https://github.com/claration/Feather"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    settingsHero

                    settingsGroup(title: .localized("General")) {
                        NavigationLink {
                            AuroraLanguageSettingsView(language: $language)
                        } label: {
                            AuroraSettingsRow(
                                icon: "globe",
                                color: .orange,
                                title: .localized("Language"),
                                value: AuroraLanguageName(rawValue: language)?.title ?? "English"
                            )
                        }

                        NavigationLink(destination: AppearanceView()) {
                            AuroraSettingsRow(icon: "paintbrush", color: .orange, title: .localized("Appearance"))
                        }

                        NavigationLink(destination: AppIconView(currentIcon: $currentIcon)) {
                            AuroraSettingsRow(icon: "app.badge", color: .orange, title: .localized("App Icon"))
                        }
                    }

                    settingsGroup(title: .localized("Signing")) {
                        NavigationLink(destination: CertificatesView()) {
                            AuroraSettingsRow(
                                icon: "checkmark.seal.fill",
                                color: .orange,
                                title: .localized("Certificates"),
                                value: selectedCertificate == nil ? .localized("Not configured") : .localized("Ready")
                            )
                        }

                        NavigationLink(destination: AuroraRepositoriesSettingsView()) {
                            AuroraSettingsRow(
                                icon: "globe.desk",
                                color: .orange,
                                title: .localized("Repositories"),
                                value: .localized("Manage")
                            )
                        }

                        NavigationLink(destination: ConfigurationView()) {
                            AuroraSettingsRow(icon: "signature", color: .orange, title: .localized("Signing Options"))
                        }
                    }

                    settingsGroup(title: .localized("Advanced")) {
                        NavigationLink(destination: InstallationView()) {
                            AuroraSettingsRow(icon: "arrow.down.circle", color: .orange, title: .localized("Installation"))
                        }
                        NavigationLink(destination: ArchiveView()) {
                            AuroraSettingsRow(icon: "archivebox", color: .orange, title: .localized("Archive & Compression"))
                        }
                        NavigationLink(destination: ResetView()) {
                            AuroraSettingsRow(icon: "arrow.counterclockwise", color: .orange, title: .localized("Reset"))
                        }
                    }

                    _directories()

                    _feedback()

                    Text(.localized("Advanced options are kept here so the main app stays simple."))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(.localized("Settings"))
            .navigationBarTitleDisplayMode(.large)
        }
        .environment(\.locale, Locale(identifier: language))
    }

    private var settingsHero: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.orange.gradient)
                Image(systemName: "gearshape.2.fill")
                    .font(.system(size: 24, weight: .bold))
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
            Spacer()
        }
        .padding(16)
        .auroraSettingsGlass(cornerRadius: 24)
    }

    @ViewBuilder
    private func settingsGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
            VStack(spacing: 0) {
                content()
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .auroraSettingsGlass(cornerRadius: 20)
        }
    }
}

private enum AuroraLanguageName: String {
    case en, ko
    case zhHans = "zh-Hans"
    case ja, es

    var title: String {
        switch self {
        case .en: return "English"
        case .ko: return "한국어"
        case .zhHans: return "简体中文"
        case .ja: return "日本語"
        case .es: return "Español"
        }
    }
}

private struct AuroraLanguageSettingsView: View {
    @Binding var language: String

    var body: some View {
        List {
            Section {
                ForEach([
                    ("en", "🇺🇸", "English"),
                    ("ko", "🇰🇷", "한국어"),
                    ("zh-Hans", "🇨🇳", "简体中文"),
                    ("ja", "🇯🇵", "日本語"),
                    ("es", "🇪🇸", "Español")
                ], id: \.0) { item in
                    Button {
                        language = item.0
                    } label: {
                        HStack {
                            Text(item.1)
                            Text(item.2)
                            Spacer()
                            if language == item.0 {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.orange)
                                    .fontWeight(.bold)
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

private struct AuroraSettingsRow: View {
    let icon: String
    let color: Color
    let title: String
    var value: String?

    init(icon: String, color: Color, title: String, value: String? = nil) {
        self.icon = icon
        self.color = color
        self.title = title
        self.value = value
    }

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(color.gradient, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            Text(title)
                .font(.body.weight(.medium))

            Spacer()

            if let value {
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
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

private extension View {
    @ViewBuilder
    func auroraSettingsGlass(cornerRadius: CGFloat) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular.tint(.orange.opacity(0.08)), in: .rect(cornerRadius: cornerRadius))
        } else {
            self.background(.thinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color.orange.opacity(0.12), lineWidth: 0.8)
                }
        }
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
                        .foregroundStyle(.orange)
                }
            } footer: {
                Text(.localized("Add and manage the repositories used by the App Store."))
            }

            Section(.localized("Repositories")) {
                if sources.isEmpty {
                    Text(.localized("No Repositories"))
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sources) { source in
                        HStack(spacing: 12) {
                            Image(systemName: "globe")
                                .foregroundStyle(.orange)
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
                .tint(.orange)
            }
        }
        .sheet(isPresented: $showAddSource) {
            SourcesAddView()
                .presentationDetents([.medium, .large])
        }
        .task(id: Array(sources)) {
            await viewModel.fetchSources(sources)
        }
    }
}

// MARK: - View extension
extension SettingsView {
	@ViewBuilder
	private func _feedback() -> some View {
		Section {
			NavigationLink(destination: AboutView()) {
				Label {
					Text(verbatim: .localized("About %@", arguments: Bundle.main.name))
				} icon: {
					FRAppIconView(size: 23)
				}
			}
            
			Button(.localized("Submit Feedback"), systemImage: "safari") {
				let bugAction: UIAlertAction = .init(title: .localized("Bug Report"), style: .default) { _ in
					UIApplication.open(_makeGitHubIssueURL(url: githubUrl))
				}
				
				let chooseAction: UIAlertAction = .init(title: .localized("Other"), style: .default) { _ in
					UIApplication.open(URL(string: "\(githubUrl)/issues/new/choose")!)
				}
				
				UIAlertController.showAlertWithCancel(
					title: .localized("Submit Feedback"),
					message: nil,
					actions: [bugAction, chooseAction]
				)
			}
			Button(.localized("GitHub Repository"), systemImage: "safari") {
				UIApplication.open(githubUrl)
			}
		} footer: {
			Text(.localized("If any issues occur within the app please report it via the GitHub repository. When submitting an issue, make sure to submit detailed information."))
		}
	}
    
	@ViewBuilder
	private func _directories() -> some View {
		NBSection(.localized("Misc")) {
			Button(.localized("Open Documents"), systemImage: "folder") {
				UIApplication.open(URL.documentsDirectory.toSharedDocumentsURL()!)
			}
			Button(.localized("Open Archives"), systemImage: "folder") {
				UIApplication.open(FileManager.default.archives.toSharedDocumentsURL()!)
			}
			Button(.localized("Open Certificates"), systemImage: "folder") {
				UIApplication.open(FileManager.default.certificates.toSharedDocumentsURL()!)
			}
		} footer: {
			Text(.localized("All of the apps files are contained in the documents directory, here are some quick links to these."))
		}
	}
    
	private func _makeGitHubIssueURL(url: String) -> String {
		var configurationSection = "### App Configuration:\n"
		
		switch UserDefaults.standard.integer(forKey: "Feather.installationMethod") {
		case 0: // Server
			let serverMethod = UserDefaults.standard.integer(forKey: "Feather.serverMethod")
			let ipFix = UserDefaults.standard.bool(forKey: "Feather.ipFix")
			let serverType = (serverMethod == 0) ? "Fully Local" : "Semi Local"
			configurationSection += "- Install method: `Server`\n"
			configurationSection += "  - Server type: `\(serverType)`\n"
			configurationSection += "  - IP Fix: `\(ipFix)`\n"
		case 1: // idevice
			let pairingPath = HeartbeatManager.pairingFile()
			let pairingExists = FileManager.default.fileExists(atPath: pairingPath)
			let pairingStatus = pairingExists ? "`Present`" : "`Not Present`"
			configurationSection += "- Install method: `idevice`\n"
			configurationSection += "  - Pairing file: \(pairingStatus)\n"
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
		let encodedTitle = "[Bug] replace this with a descriptive title "
			.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
		let encodedBody = body
			.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
		return "\(url)/issues/new?template=bug.yml&title=\(encodedTitle)&text=\(encodedBody)"
	}
}
