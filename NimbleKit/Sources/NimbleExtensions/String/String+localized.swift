//
//  String+localized.swift
//  NimbleKit
//
//  Created by samara on 20.03.2025.
//

import Foundation
import SwiftUI

/// Caches `.lproj` bundles so the app can localize strings with a language
/// chosen inside the app instead of the system language only.
private final class NBLocalizationBundleCache {
	static let shared = NBLocalizationBundleCache()

	/// Key the app writes when the user picks a language in onboarding/settings.
	static let languageKey = "aurora.language"

	private let _lock = NSLock()
	private var _cache: [String: Bundle] = [:]

	func bundle(for language: String) -> Bundle {
		_lock.lock()
		defer { _lock.unlock() }

		if let cached = _cache[language] {
			return cached
		}

		guard
			let path = Bundle.main.path(forResource: language, ofType: "lproj"),
			let bundle = Bundle(path: path)
		else {
			return .main
		}

		_cache[language] = bundle
		return bundle
	}
}

extension String {
	// from: https://github.com/NSAntoine/Antoine/blob/main/Antoine/Backend/Extensions/Foundation.swift#L43-L55
	// was given permission to use any code from antoine as I like - thank you Serena!~

	/// Bundle matching the in-app language selection, falling back to `.main`.
	static private var _localizationBundle: Bundle {
		guard
			let language = UserDefaults.standard.string(forKey: NBLocalizationBundleCache.languageKey),
			!language.isEmpty
		else {
			return .main
		}

		return NBLocalizationBundleCache.shared.bundle(for: language)
	}

	static private func _lookup(_ name: String) -> String {
		let value = _localizationBundle.localizedString(forKey: name, value: nil, table: nil)

		guard value != name else {
			/// Not translated in the selected language, fall back to the main bundle.
			return NSLocalizedString(name, comment: "")
		}

		return value
	}

	static public func localized(_ name: String) -> String {
		_lookup(name)
	}

	static public func localized(_ name: String, arguments: CVarArg...) -> String {
		String(format: _lookup(name), arguments: arguments)
	}
	/// Localizes the current string using the main bundle.
	///
	/// - Returns: The localized string.
	public func localized() -> String {
		String.localized(self)
	}
}

extension LocalizedStringKey {
	static public func localized(_ key: String) -> LocalizedStringKey {
		LocalizedStringKey(key)
	}
}
