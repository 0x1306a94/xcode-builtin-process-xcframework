//
//  XCFrameworkInfo.swift
//  xcode-builtin-process-xcframework
//
//  Created by KK on 2025/1/24.
//

import Foundation

struct XCFrameworkInfo: Codable {
    let availableLibraries: [AvailableLibrary]
    let cfBundlePackageType: String
    let xcFrameworkFormatVersion: String

    enum CodingKeys: String, CodingKey {
        case availableLibraries = "AvailableLibraries"
        case cfBundlePackageType = "CFBundlePackageType"
        case xcFrameworkFormatVersion = "XCFrameworkFormatVersion"
    }
}

struct AvailableLibrary: Codable {
    let binaryPath: String?
    let headersPath: String?
    let libraryIdentifier: String
    let libraryPath: String
    let supportedArchitectures: [String]
    let supportedPlatform: String
    let supportedPlatformVariant: String?

    enum CodingKeys: String, CodingKey {
        case binaryPath = "BinaryPath"
        case headersPath = "HeadersPath"
        case libraryIdentifier = "LibraryIdentifier"
        case libraryPath = "LibraryPath"
        case supportedArchitectures = "SupportedArchitectures"
        case supportedPlatform = "SupportedPlatform"
        case supportedPlatformVariant = "SupportedPlatformVariant"
    }
}
