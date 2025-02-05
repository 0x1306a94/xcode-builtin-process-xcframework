import ArgumentParser
import Foundation

enum Platform: String, ExpressibleByArgument {
    case ios
    case macos
    case watchos
    case tvos
    case xros
    case driverkit
}

enum Environment: String, ExpressibleByArgument {
    case simulator
    case maccatalyst
}

struct Command: ParsableCommand {
    @Option(name: .customLong("xcframework"), help: "xcframework path")
    var source: String

    @Option(name: .long, help: "platform: [ios, macos, watchos, driverkit, tvos, xros]")
    var platform: Platform

    @Option(help: "environment: [simulator, maccatalyst]")
    var environment: Environment? = nil

    @Option(name: .long, help: "target path")
    var targetPath: String

    mutating func validate() throws {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false

        if !fileManager.fileExists(atPath: source, isDirectory: &isDirectory) {
            throw ValidationError("The xcframework path does not exist: \(source)")
        }

        if !isDirectory.boolValue {
            throw ValidationError("The specified xcframework is not a folder: \(source)")
        }

        if !source.hasSuffix(".xcframework") {
            throw ValidationError("The path must end with '.xcframework': \(source)")
        }
    }

    mutating func run() throws {
        let platformDisplayName = "\(platform.rawValue)" + (environment.flatMap { "-\($0.rawValue)" } ?? "")

        print("[*] xcframework: \(source)")
        print("[*] platform: \(platformDisplayName)")

        let sourcePath = URL(fileURLWithPath: source)
        let targetPath = URL(fileURLWithPath: targetPath)
        let plistPath = sourcePath.join("Info.plist")
        let fs = FileManager.default
        guard fs.fileExists(atPath: plistPath.path) else {
            throw ValidationError("There is no Info.plist found at '\(source)'.")
        }

        let plistData = try Data(contentsOf: plistPath)

        let decoder = PropertyListDecoder()
        let xcFrameworkInfo = try decoder.decode(XCFrameworkInfoPlist_V1.self, from: plistData)

        guard let library = xcFrameworkInfo.findLibrary(platform: platform.rawValue, platformVariant: environment?.rawValue ?? "") else {
            throw ValidationError("While building for \(platformDisplayName), no library for this platform was found in '\(sourcePath.lastPathComponent)'.")
        }

        print("[*] library: \(library)")
        let rootPathToLibrary = sourcePath.join(library.libraryIdentifier)
        let copyLibraryFromPath = rootPathToLibrary.join(library.libraryPath)

        let copyLibraryToPath = targetPath
        let libraryTargetPath = copyLibraryToPath.join(library.libraryPath)

        if !fs.fileExists(atPath: copyLibraryFromPath.path) {
            throw ValidationError("When building for \(platformDisplayName), the expected library \(copyLibraryFromPath.path) was not found in \(sourcePath.path)")
        }

        try fs.createDirectory(at: targetPath, withIntermediateDirectories: true)
        try fs.copyItemWithOverwrite(at: copyLibraryFromPath, to: libraryTargetPath)

        if let debugSymbolsPath = library.debugSymbolsPath {
            let copyDebugSymbolsFromPath = rootPathToLibrary.join(debugSymbolsPath)
            let copyDebugSymbolsToPath = copyLibraryToPath
            try fs.copyItemWithOverwrite(at: copyDebugSymbolsFromPath, to: copyDebugSymbolsToPath)
        }

        if let bitcodeSymbolMapsPath = library.bitcodeSymbolMapsPath {
            let copyBitcodeSymbolMapsFromPath = rootPathToLibrary.join(bitcodeSymbolMapsPath)
            let copyBitcodeSymbolMapsToPath = copyLibraryToPath
            try fs.copyItemWithOverwrite(at: copyBitcodeSymbolMapsFromPath, to: copyBitcodeSymbolMapsToPath)
        }

        if let headersPath = library.headersPath {
            let copyHeadersFromPath = rootPathToLibrary.join(headersPath)
            let copyHeadersToPath = copyLibraryToPath.join("include")
            try fs.copyItemWithOverwrite(at: copyHeadersFromPath, to: copyHeadersToPath)
        }

        // ["dylib", "a"]
        if library.libraryPath.hasSuffix("dylib") || library.libraryPath.hasSuffix(".a") {
            for file in try fs.contentsOfDirectory(atPath: rootPathToLibrary.path) {
                let filePath = rootPathToLibrary.join(file)

                let swiftExtensions = ["swiftinterface", "swiftmodule", "swiftdoc"]
                if swiftExtensions.contains(filePath.pathExtension) {
                    let destinationPath = copyLibraryToPath.join(file)
                    try fs.copyItemWithOverwrite(at: filePath, to: destinationPath)
                }
            }
        }
    }
}

import Foundation

extension URL {
    func join(_ path: String) -> URL {
        if #available(macOS 13.0, *) {
            return self.appending(components: path)
        } else {
            return appendingPathComponent(path)
        }
    }
}

extension FileManager {
    /// 拷贝文件并覆盖目标文件（如果目标文件已存在）
    ///
    /// - Parameters:
    ///   - sourceURL: 源文件的路径
    ///   - destinationURL: 目标文件的路径
    /// - Throws: 如果发生错误，会抛出异常
    func copyItemWithOverwrite(at sourceURL: URL, to destinationURL: URL) throws {
        if fileExists(atPath: destinationURL.path) {
            print("[*] Removing \(destinationURL.path)")
            try removeItem(at: destinationURL)
        }
        print("[*] Copying \(sourceURL.path) to \(destinationURL.path)")
        try copyItem(at: sourceURL, to: destinationURL)
    }
}
