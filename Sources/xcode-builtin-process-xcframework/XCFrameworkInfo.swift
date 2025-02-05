//
//  XCFrameworkInfo.swift
//  xcode-builtin-process-xcframework
//
//  Created by KK on 2025/1/24.
//

import Foundation

struct XCFrameworkInfoPlist_V1: Codable {
    struct Library: Codable {
        let libraryIdentifier: String
        let supportedPlatform: String
        let supportedArchitectures: [String]
        let platformVariant: String?
        let libraryPath: String
        // This is optional because XCFrameworks created with Xcode 14.x and earlier will not define it, but should still be usable.
        let binaryPath: String?
        let headersPath: String?
        let debugSymbolsPath: String?
        // This is optional because we only want to encode it if the XCFramework is at least of the version which supports it, but this struct doesn't know what that is, so we capture that characteristic in XCFramework.serialize() where the version is available.
        let mergeableMetadata: Bool?
        let bitcodeSymbolMapsPath: String?

        enum CodingKeys: String, CodingKey {
            case libraryIdentifier = "LibraryIdentifier"
            case supportedPlatform = "SupportedPlatform"
            case supportedArchitectures = "SupportedArchitectures"
            case platformVariant = "SupportedPlatformVariant"
            case libraryPath = "LibraryPath"
            case binaryPath = "BinaryPath"
            case headersPath = "HeadersPath"
            case debugSymbolsPath = "DebugSymbolsPath"
            case mergeableMetadata = "MergeableMetadata"
            case bitcodeSymbolMapsPath = "BitcodeSymbolMapsPath"
        }

        init(libraryIdentifier: String, supportedPlatform: String, supportedArchitectures: [String], platformVariant: String?, libraryPath: String, binaryPath: String?, headersPath: String?, debugSymbolsPath: String?, mergeableMetadata: Bool?, bitcodeSymbolMapsPath: String?) {
            self.libraryIdentifier = libraryIdentifier
            self.supportedPlatform = supportedPlatform
            self.supportedArchitectures = supportedArchitectures
            self.platformVariant = platformVariant
            self.libraryPath = libraryPath
            self.binaryPath = binaryPath
            self.headersPath = headersPath
            self.debugSymbolsPath = debugSymbolsPath
            self.mergeableMetadata = mergeableMetadata
            self.bitcodeSymbolMapsPath = bitcodeSymbolMapsPath
        }

        // NOTE: The mappings for maccatalyst are so that "macabi" is used as that is what is directly matched in the LC_BUILD_VERSION info.

        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(libraryIdentifier, forKey: .libraryIdentifier)
            try container.encode(supportedPlatform, forKey: .supportedPlatform)
            try container.encode(supportedArchitectures, forKey: .supportedArchitectures)

            if platformVariant == "macabi" {
                try container.encode("maccatalyst", forKey: .platformVariant)
            }
            else {
                try container.encodeIfPresent(platformVariant, forKey: .platformVariant)
            }

            try container.encode(libraryPath, forKey: .libraryPath)
            try container.encode(binaryPath, forKey: .binaryPath)
            try container.encodeIfPresent(headersPath, forKey: .headersPath)
            try container.encodeIfPresent(debugSymbolsPath, forKey: .debugSymbolsPath)
            try container.encodeIfPresent(mergeableMetadata, forKey: .mergeableMetadata)
            try container.encodeIfPresent(bitcodeSymbolMapsPath, forKey: .bitcodeSymbolMapsPath)
        }

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.libraryIdentifier = try container.decode(String.self, forKey: .libraryIdentifier)
            self.supportedPlatform = try container.decode(String.self, forKey: .supportedPlatform)
            self.supportedArchitectures = try container.decode([String].self, forKey: .supportedArchitectures)
            var platformVariant = try container.decodeIfPresent(String.self, forKey: .platformVariant)
            if platformVariant == "maccatalyst" {
                platformVariant = "macabi"
            }
            self.platformVariant = platformVariant

            self.libraryPath = try container.decode(String.self, forKey: .libraryPath)
            self.binaryPath = try container.decodeIfPresent(String.self, forKey: .binaryPath)
            self.headersPath = try container.decodeIfPresent(String.self, forKey: .headersPath)
            self.debugSymbolsPath = try container.decodeIfPresent(String.self, forKey: .debugSymbolsPath)
            self.mergeableMetadata = try container.decodeIfPresent(Bool.self, forKey: .mergeableMetadata)
            self.bitcodeSymbolMapsPath = try container.decodeIfPresent(String.self, forKey: .bitcodeSymbolMapsPath)
        }
    }

    let version: String
    let libraries: [Library]

    let bundleCode: String = "XFWK"

    enum CodingKeys: String, CodingKey {
        case version = "XCFrameworkFormatVersion"
        case libraries = "AvailableLibraries"
        case bundleCode = "CFBundlePackageType"
    }
}

extension XCFrameworkInfoPlist_V1 {
    func findLibrary(platform: String, platformVariant: String = "") -> Library? {
        return libraries.filter { lib in
            // Due to the fact that macro evaluation of empty settings returns empty strings, there is no meaningful distinction between nil and empty here.
            lib.supportedPlatform == platform && (lib.platformVariant ?? "") == platformVariant
        }.first
    }
}
