import Foundation

enum L10n {
    static func string(_ key: String, locale: Locale) -> String {
        String(localized: String.LocalizationValue(key), bundle: .main, locale: locale)
    }

    static func format(_ key: String, locale: Locale, _ arguments: CVarArg...) -> String {
        let template = string(key, locale: locale)
        return String(format: template, locale: locale, arguments: arguments)
    }
}
