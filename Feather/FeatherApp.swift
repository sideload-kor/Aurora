//
//  FeatherApp.swift
//  Feather
//
//  Created by samara on 10.04.2025.
//

import SwiftUI
import Nuke
import IDeviceSwift
import OSLog

@main
struct FeatherApp: App {
	@UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
	@AppStorage("aurora.language") private var language = "en"
	@AppStorage("aurora.hasCompletedOnboarding") private var hasCompletedOnboarding = false
	
	let heartbeat = HeartbeatManager.shared
	
	@StateObject var downloadManager = DownloadManager.shared
	let storage = Storage.shared
	
	var body: some Scene {
		WindowGroup {
			VStack(spacing: 0) {
				if hasCompletedOnboarding {
					DownloadHeaderView(downloadManager: downloadManager)
						.transition(.move(edge: .top).combined(with: .opacity))
					VariedTabbarView()
						.transition(.move(edge: .top).combined(with: .opacity))
				} else {
					AuroraOnboardingView()
						.transition(.opacity)
				}
			}
			.environment(\.managedObjectContext, storage.context)
			.onOpenURL(perform: _handleURL)
			.animation(.smooth, value: downloadManager.manualDownloads.description)
			.environment(\.locale, Locale(identifier: language))
			.onReceive(NotificationCenter.default.publisher(for: .heartbeatInvalidHost)) { _ in
				DispatchQueue.main.async {
					UIAlertController.showAlertWithOk(
						title: "InvalidHostID",
						message: .localized("Your pairing file is invalid and is incompatible with your device, please import a valid pairing file.")
					)
				}
			}
			// dear god help me
			.onAppear {
				if let style = UIUserInterfaceStyle(rawValue: UserDefaults.standard.integer(forKey: "Feather.userInterfaceStyle")) {
					UIApplication.topViewController()?.view.window?.overrideUserInterfaceStyle = style
				}
				
				UIApplication.topViewController()?.view.window?.tintColor = UIColor(Color(hex: UserDefaults.standard.string(forKey: "Feather.userTintColor") ?? "#848ef9"))
			}
		}
	}
	
	private func _handleURL(_ url: URL) {
		if url.scheme == "feather" {
			/// feather://import-certificate?p12=<base64>&mobileprovision=<base64>&password=<base64>
			if url.host == "import-certificate" {
				guard
					let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
					let queryItems = components.queryItems
				else {
					return
				}
				
				func queryValue(_ name: String) -> String? {
					queryItems.first(where: { $0.name == name })?.value?.removingPercentEncoding
				}
				
				guard
					let p12Base64 = queryValue("p12"),
					let provisionBase64 = queryValue("mobileprovision"),
					let passwordBase64 = queryValue("password"),
					let passwordData = Data(base64Encoded: passwordBase64),
					let password = String(data: passwordData, encoding: .utf8)
				else {
					return
				}
				
				let generator = UINotificationFeedbackGenerator()
				generator.prepare()
				
				guard
					let p12URL = FileManager.default.decodeAndWrite(base64: p12Base64, pathComponent: ".p12"),
					let provisionURL = FileManager.default.decodeAndWrite(base64: provisionBase64, pathComponent: ".mobileprovision"),
					FR.checkPasswordForCertificate(for: p12URL, with: password, using: provisionURL)
				else {
					generator.notificationOccurred(.error)
					return
				}
				
				FR.handleCertificateFiles(
					p12URL: p12URL,
					provisionURL: provisionURL,
					p12Password: password
				) { error in
					if let error = error {
						UIAlertController.showAlertWithOk(title: .localized("Error"), message: error.localizedDescription)
					} else {
						generator.notificationOccurred(.success)
					}
				}
				
				return
			}
			/// feather://export-certificate?callback_template=<template>
			/// ?callback_template=: This is how we callback to the application requesting the certificate, this will be a url scheme
			/// 	example: livecontainer%3A%2F%2Fcertificate%3Fcert%3D%24%28BASE64_CERT%29%26password%3D%24%28PASSWORD%29
			/// 	decoded: livecontainer://certificate?cert=$(BASE64_CERT)&password=$(PASSWORD)
			/// $(BASE64_CERT) and $(PASSWORD) must be presenting in the callback template so we can replace them with the proper content
			if url.host == "export-certificate" {
				guard
					let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
				else {
					return
				}
				
				let queryItems = components.queryItems?.reduce(into: [String: String]()) { $0[$1.name.lowercased()] = $1.value } ?? [:]
				guard let callbackTemplate = queryItems["callback_template"]?.removingPercentEncoding else { return }
				
				FR.exportCertificateAndOpenUrl(using: callbackTemplate)
			}
			/// feather://source/<url>
			if let fullPath = url.validatedScheme(after: "/source/") {
				FR.handleSource(fullPath) { }
			}
			/// feather://install/<url.ipa>
			if
				let fullPath = url.validatedScheme(after: "/install/"),
				let downloadURL = URL(string: fullPath)
			{
				UIAlertController.showAlertWithCancel(
					title: .localized("Install"),
					message: .localized("Do you want to download and install this file?") + "\n\n\(downloadURL)",
					actions: [
						UIAlertAction(title: .localized("Install"), style: .default) { _ in
							_ = DownloadManager.shared.startDownload(from: downloadURL)
						}
					]
				)
			}
		} else {
			if url.pathExtension == "ipa" || url.pathExtension == "tipa" {
				if FileManager.default.isFileFromFileProvider(at: url) {
					guard url.startAccessingSecurityScopedResource() else { return }
					FR.handlePackageFile(url) { _ in }
				} else {
					FR.handlePackageFile(url) { _ in }
				}
				
				return
			}
		}
	}
}

class AppDelegate: NSObject, UIApplicationDelegate {
	func application(
		_ application: UIApplication,
		didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
	) -> Bool {
		_createPipeline()
		_createDocumentsDirectories()
		ResetView.clearWorkCache()
		_addDefaultCertificates()
		return true
	}
	
	private func _createPipeline() {
		DataLoader.sharedUrlCache.diskCapacity = 0
		
		let pipeline = ImagePipeline {
			let dataLoader: DataLoader = {
				let config = URLSessionConfiguration.default
				config.urlCache = nil
				return DataLoader(configuration: config)
			}()
			let dataCache = try? DataCache(name: "thewonderofyou.Feather.datacache") // disk cache
			let imageCache = Nuke.ImageCache() // memory cache
			dataCache?.sizeLimit = 500 * 1024 * 1024
			imageCache.costLimit = 100 * 1024 * 1024
			$0.dataCache = dataCache
			$0.imageCache = imageCache
			$0.dataLoader = dataLoader
			$0.dataCachePolicy = .automatic
			$0.isStoringPreviewsInMemoryCache = false
		}
		
		ImagePipeline.shared = pipeline
	}
	
	private func _createDocumentsDirectories() {
		let fileManager = FileManager.default

		let directories: [URL] = [
			fileManager.archives,
			fileManager.certificates,
			fileManager.signed,
			fileManager.unsigned
		]
		
		for url in directories {
			try? fileManager.createDirectoryIfNeeded(at: url)
		}
	}
	
	private func _addDefaultCertificates() {
		guard
			UserDefaults.standard.bool(forKey: "feather.didImportDefaultCertificates") == false,
			let signingAssetsURL = Bundle.main.url(forResource: "signing-assets", withExtension: nil)
		else {
			return
		}
		
		do {
			let folderContents = try FileManager.default.contentsOfDirectory(
				at: signingAssetsURL,
				includingPropertiesForKeys: nil,
				options: .skipsHiddenFiles
			)
			
			for folderURL in folderContents {
				guard folderURL.hasDirectoryPath else { continue }
				
				let certName = folderURL.lastPathComponent
				
				let p12Url = folderURL.appendingPathComponent("cert.p12")
				let provisionUrl = folderURL.appendingPathComponent("cert.mobileprovision")
				let passwordUrl = folderURL.appendingPathComponent("cert.txt")
				
				guard
					FileManager.default.fileExists(atPath: p12Url.path),
					FileManager.default.fileExists(atPath: provisionUrl.path),
					FileManager.default.fileExists(atPath: passwordUrl.path)
				else {
					Logger.misc.warning("Skipping \(certName): missing required files")
					continue
				}
				
				let password = try String(contentsOf: passwordUrl, encoding: .utf8)
				
				FR.handleCertificateFiles(
					p12URL: p12Url,
					provisionURL: provisionUrl,
					p12Password: password,
					certificateName: certName,
					isDefault: true
				) { _ in
					
				}
			}
			UserDefaults.standard.set(true, forKey: "feather.didImportDefaultCertificates")
		} catch {
			Logger.misc.error("Failed to list signing-assets: \(error)")
		}
	}

}


// MARK: - Aurora onboarding

private enum AuroraLanguage: String, CaseIterable, Identifiable {
	case english = "en"
	case korean = "ko"
	case chinese = "zh-Hans"
	case japanese = "ja"
	case spanish = "es"

	var id: String { rawValue }

	var title: String {
		switch self {
		case .english: return "English"
		case .korean: return "한국어"
		case .chinese: return "简体中文"
		case .japanese: return "日本語"
		case .spanish: return "Español"
		}
	}

	var flag: String {
		switch self {
		case .english: return "🇺🇸"
		case .korean: return "🇰🇷"
		case .chinese: return "🇨🇳"
		case .japanese: return "🇯🇵"
		case .spanish: return "🇪🇸"
		}
	}
}

private struct AuroraOnboardingView: View {
	@AppStorage("aurora.language") private var language = "en"
	@AppStorage("aurora.hasCompletedOnboarding") private var completed = false
	@State private var page = 0

	private var selectedLanguage: AuroraLanguage {
		AuroraLanguage(rawValue: language) ?? .english
	}

	var body: some View {
		ZStack {
			AuroraBackground()

			VStack(spacing: 0) {
				HStack {
					Spacer()
					Button(.localized("Skip")) {
						completed = true
					}
					.font(.subheadline.weight(.semibold))
					.foregroundStyle(.secondary)
					.padding(.horizontal, 22)
					.padding(.top, 18)
				}

				TabView(selection: $page) {
					AuroraIntroPage(
						icon: "sparkles",
						title: .localized("Welcome to Aurora"),
						subtitle: .localized("A cleaner, faster way to discover and install your apps."),
						accent: .orange
					).tag(0)

					AuroraLanguagePage(language: $language).tag(1)

					AuroraQuickSetupPage(showSource: $showSource).tag(2)
				}
				.tabViewStyle(.page(indexDisplayMode: .never))

				HStack(spacing: 7) {
					ForEach(0..<3, id: \.self) { index in
						Capsule()
							.fill(index == page ? Color.orange : Color.secondary.opacity(0.22))
							.frame(width: index == page ? 22 : 7, height: 7)
							.animation(.smooth, value: page)
					}
				}
				.padding(.bottom, 18)

				Button {
					if page < 2 {
						withAnimation(.smooth) { page += 1 }
					} else {
						completed = true
					}
				} label: {
					HStack(spacing: 8) {
						Text(page == 2 ? .localized("Start Using Aurora") : .localized("Continue"))
						Image(systemName: page == 2 ? "checkmark" : "arrow.right")
					}
					.font(.headline)
					.frame(maxWidth: .infinity)
					.padding(.vertical, 16)
				}
				.buttonStyle(AuroraPrimaryButtonStyle())
				.padding(.horizontal, 22)
				.padding(.bottom, 20)
			}
		}
		.environment(\.locale, Locale(identifier: language))
	}
}

private struct AuroraIntroPage: View {
	let icon: String
	let title: String
	let subtitle: String
	let accent: Color

	var body: some View {
		VStack(spacing: 24) {
			Spacer()
			AuroraGlassIcon(systemName: icon, color: accent)
			Text(title)
				.font(.system(size: 36, weight: .bold, design: .rounded))
				.multilineTextAlignment(.center)
			Text(subtitle)
				.font(.title3)
				.foregroundStyle(.secondary)
				.multilineTextAlignment(.center)
				.frame(maxWidth: 420)
			Spacer()
		}
		.padding(.horizontal, 28)
	}
}

private struct AuroraLanguagePage: View {
	@Binding var language: String

	var body: some View {
		VStack(alignment: .leading, spacing: 18) {
			Spacer()
			Text(.localized("Choose your language"))
				.font(.system(size: 34, weight: .bold, design: .rounded))
			Text(.localized("You can change this anytime in Settings."))
				.foregroundStyle(.secondary)
			ScrollView {
				VStack(spacing: 10) {
					ForEach(AuroraLanguage.allCases) { item in
						Button {
							withAnimation(.smooth) { language = item.rawValue }
						}
						label: {
							HStack(spacing: 14) {
								Text(item.flag).font(.title2)
								Text(item.title).font(.body.weight(.semibold))
								Spacer()
								if language == item.rawValue {
									Image(systemName: "checkmark.circle.fill")
										.foregroundStyle(.orange)
								}
							}
							.padding(16)
							.background(AuroraGlassShape(cornerRadius: 18))
						}
						.buttonStyle(.plain)
					}
				}
			}
			Spacer()
		}
		.padding(.horizontal, 22)
	}
}

private struct AuroraQuickSetupPage: View {

	var body: some View {
		VStack(spacing: 20) {
			Spacer()
			AuroraGlassIcon(systemName: "wand.and.stars", color: .orange)
			Text(.localized("You're ready"))
				.font(.system(size: 36, weight: .bold, design: .rounded))
			Text(.localized("Aurora keeps advanced options out of your way. Sources, certificates, signing and other technical settings live neatly in Settings."))
				.font(.title3)
				.foregroundStyle(.secondary)
				.multilineTextAlignment(.center)
			Text(.localized("Your App Store starts on the Sources screen, while technical setup stays in Settings."))
				.font(.subheadline)
				.foregroundStyle(.orange)
				.multilineTextAlignment(.center)
			Spacer()
		}
		.padding(.horizontal, 24)
	}
}

private struct AuroraGlassIcon: View {
	let systemName: String
	let color: Color

	var body: some View {
		Image(systemName: systemName)
			.font(.system(size: 42, weight: .semibold))
			.foregroundStyle(color)
			.frame(width: 108, height: 108)
			.background(AuroraGlassShape(cornerRadius: 32))
			.shadow(color: .orange.opacity(0.14), radius: 24, y: 12)
	}
}

private struct AuroraBackground: View {
	var body: some View {
		ZStack {
			Color(.systemGroupedBackground)
			Circle()
				.fill(Color.orange.opacity(0.12))
				.frame(width: 320)
				.blur(radius: 70)
				.offset(x: 150, y: -300)
			Circle()
				.fill(Color.orange.opacity(0.07))
				.frame(width: 260)
				.blur(radius: 70)
				.offset(x: -160, y: 300)
		}
		.ignoresSafeArea()
	}
}

private struct AuroraGlassShape: View {
	let cornerRadius: CGFloat

	var body: some View {
		if #available(iOS 26.0, *) {
			RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
				.fill(.clear)
				.glassEffect(.regular.tint(.orange.opacity(0.08)), in: .rect(cornerRadius: cornerRadius))
		} else {
			RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
				.fill(.thinMaterial)
				.overlay {
					RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
						.strokeBorder(.white.opacity(0.14), lineWidth: 0.7)
				}
		}
	}
}

private struct AuroraPrimaryButtonStyle: ButtonStyle {
	func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.foregroundStyle(.white)
			.background(
				RoundedRectangle(cornerRadius: 18, style: .continuous)
					.fill(Color.orange.gradient)
			)
			.opacity(configuration.isPressed ? 0.78 : 1)
			.scaleEffect(configuration.isPressed ? 0.985 : 1)
	}
}

private struct AuroraSecondaryButtonStyle: ButtonStyle {
	func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.foregroundStyle(.orange)
			.background(
				RoundedRectangle(cornerRadius: 18, style: .continuous)
					.fill(.thinMaterial)
			)
			.overlay {
				RoundedRectangle(cornerRadius: 18, style: .continuous)
					.strokeBorder(Color.orange.opacity(0.25), lineWidth: 1)
			}
			.opacity(configuration.isPressed ? 0.72 : 1)
	}
}
