import ArgumentParser
import Foundation

enum Platform: String, ExpressibleByArgument {
    case ios
    case macos
    case watchos
    case tvos
    case xros
}

enum Environment: String, ExpressibleByArgument {
    case simulator
    case maccatalyst
}

struct Command: ParsableCommand {
    @Option(name: .long, help: "xcframework path")
    var xcframework: String

    @Option(name: .long, help: "platform: [ios, macos, watchos, tvos, xros]")
    var platform: Platform

    @Option(help: "environment: [simulator, maccatalyst]")
    var environment: Environment? = nil

    @Option(name: .long, help: "target path")
    var targetPath: String

    mutating func validate() throws {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false

        if !fileManager.fileExists(atPath: xcframework, isDirectory: &isDirectory) {
            throw ValidationError("The xcframework path does not exist: \(xcframework)")
        }

        if !isDirectory.boolValue {
            throw ValidationError("The specified xcframework is not a folder: \(xcframework)")
        }

        if !xcframework.hasSuffix(".xcframework") {
            throw ValidationError("The path must end with '.xcframework': \(xcframework)")
        }

        if !fileManager.fileExists(atPath: targetPath, isDirectory: &isDirectory) {
            throw ValidationError("The targetPath path does not exist: \(targetPath)")
        }

        if !isDirectory.boolValue {
            throw ValidationError("The specified targetPath is not a folder: \(targetPath)")
        }
    }

    mutating func run() throws {
        print("[*] xcframework: \(xcframework)")
        print("[*] platform: \(platform.rawValue)")
        if let environment = environment {
            print("[*] environment: \(environment.rawValue)")
        }

        let rootURL = URL(fileURLWithPath: xcframework)
        let targetRootURL = URL(fileURLWithPath: targetPath)

        let infoURL = rootURL.appendingPathComponent("Info.plist")
        let plistData = try Data(contentsOf: infoURL)

        let decoder = PropertyListDecoder()
        let xcFrameworkInfo = try decoder.decode(XCFrameworkInfo.self, from: plistData)

        guard let library = xcFrameworkInfo.availableLibraries.first(where: {
            if let environment {
                guard let supportedPlatformVariant = $0.supportedPlatformVariant, supportedPlatformVariant == environment.rawValue else {
                    return false
                }
                return true
            }

            guard $0.supportedPlatform == platform.rawValue, $0.supportedPlatformVariant == nil else {
                return false
            }

            return true

        }) else {
            if let environment {
                throw ValidationError("Unsupported platform:\(platform.rawValue) or environment:\(environment.rawValue)")
            } else {
                throw ValidationError("Unsupported platform:\(platform.rawValue) or ")
            }
        }

        let fm = FileManager.default
        let libraryRootURL = rootURL.appendingPathComponent(library.libraryIdentifier)
        let libraryPath = libraryRootURL.appendingPathComponent(library.libraryPath)
        let targetURL = targetRootURL.appendingPathComponent(library.libraryPath)
        try fm.copyItemWithOverwrite(at: libraryPath, to: targetURL)

        guard let headersPath = library.headersPath else {
            return
        }
        let headersURL = libraryRootURL.appendingPathComponent(headersPath)
        if !fm.fileExists(atPath: headersURL.path) {
            return
        }

        let targetHeadersURL = targetRootURL.appendingPathComponent("include")

        var isDirectory: ObjCBool = false

        // 检查路径是否存在并且是文件夹
        if !fm.fileExists(atPath: targetHeadersURL.path, isDirectory: &isDirectory) {
            try fm.createDirectory(at: targetHeadersURL, withIntermediateDirectories: true)
        }

        let contents = try fm.contentsOfDirectory(at: headersURL, includingPropertiesForKeys: nil, options: [])
        for fileURL in contents {
            let targetFileURL = targetHeadersURL.appendingPathComponent(fileURL.lastPathComponent)
            try fm.copyItemWithOverwrite(at: fileURL, to: targetFileURL)
        }
    }
}

import Foundation

extension FileManager {
    /// 拷贝文件并覆盖目标文件（如果目标文件已存在）
    ///
    /// - Parameters:
    ///   - sourceURL: 源文件的路径
    ///   - destinationURL: 目标文件的路径
    /// - Throws: 如果发生错误，会抛出异常
    func copyItemWithOverwrite(at sourceURL: URL, to destinationURL: URL) throws {
        print("[*] copying \(sourceURL.path) to \(destinationURL.path)")
        if fileExists(atPath: destinationURL.path) {
            try removeItem(at: destinationURL)
        }
        try copyItem(at: sourceURL, to: destinationURL)
    }
}
