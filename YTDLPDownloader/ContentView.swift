//
//  ContentView.swift
//  YTDLPDownloader
//
//  Created by Jeff Milner on 2025-11-05.
//

import SwiftUI
import UniformTypeIdentifiers
import Combine

struct ContentView: View {
    @StateObject private var downloadManager = DownloadManager()
    @State private var urlInput = ""
    @State private var selectedFormat: DownloadFormat = .mp4Best
    @State private var destinationPath = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first?.path ?? ""
    @State private var showConsole = false
    @State private var showFilePicker = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var embedThumbnail = true
    @State private var embedMetadata = true
    @State private var customFilename = ""
    @State private var useCustomFilename = false
    @State private var showSettings = false
    @State private var lastDownloadedFolderURL: URL? = nil
    @AppStorage("ytdlpPath") private var ytdlpPath = "/opt/homebrew/bin/yt-dlp"
    @AppStorage("ffmpegPath") private var ffmpegPath = "/opt/homebrew/bin/ffmpeg"

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.blue)
                        Text("yt-dlp GUI Downloader")
                            .font(.system(size: 24, weight: .bold))
                        Spacer()
                        Button(action: { showSettings.toggle() }) {
                            Image(systemName: "gearshape")
                                .font(.system(size: 18))
                        }
                        Button(action: { checkYTDLP() }) {
                            Label("Check yt-dlp", systemImage: "checkmark.circle")
                        }
                    }
                    .padding(.bottom, 5)

                    Divider()

                    // Settings Panel
                    if showSettings {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Settings")
                                .font(.headline)

                            VStack(alignment: .leading, spacing: 6) {
                                Text("yt-dlp Path")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                HStack {
                                    TextField("Path to yt-dlp", text: $ytdlpPath)
                                        .textFieldStyle(.roundedBorder)
                                        .font(.system(.body, design: .monospaced))
                                    Button("Auto-detect") { autoDetectYTDLP() }
                                }
                                Text("Common locations: /opt/homebrew/bin/yt-dlp, /usr/local/bin/yt-dlp")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Divider()

                            VStack(alignment: .leading, spacing: 6) {
                                Text("ffmpeg Path (required for merging video+audio)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                HStack {
                                    TextField("Path to ffmpeg", text: $ffmpegPath)
                                        .textFieldStyle(.roundedBorder)
                                        .font(.system(.body, design: .monospaced))
                                    Button("Auto-detect") { autoDetectFFmpeg() }
                                }
                                Text("Common locations: /opt/homebrew/bin/ffmpeg, /usr/local/bin/ffmpeg")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(8)

                        Divider()
                    }

                    // URL Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Video URL")
                            .font(.headline)
                        TextField("Enter YouTube or other video URL", text: $urlInput)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit {
                                if !urlInput.isEmpty { startDownload() }
                            }
                        Text("Supports YouTube, Vimeo, Twitter, and 1000+ sites")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Format Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Format")
                            .font(.headline)
                        Picker("Format", selection: $selectedFormat) {
                            Text("MP4 (Best Quality)").tag(DownloadFormat.mp4Best)
                            Text("MP4 (1080p)").tag(DownloadFormat.mp41080p)
                            Text("MP4 (720p)").tag(DownloadFormat.mp4720p)
                            Text("MP4 (480p)").tag(DownloadFormat.mp4480p)
                            Text("MP3 (Audio Only)").tag(DownloadFormat.mp3)
                            Text("M4A (Audio Only)").tag(DownloadFormat.m4a)
                        }
                        .pickerStyle(.segmented)
                    }

                    // Custom Filename
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Use Custom Filename", isOn: $useCustomFilename)
                            .font(.headline)
                        if useCustomFilename {
                            TextField("Filename (without extension)", text: $customFilename)
                                .textFieldStyle(.roundedBorder)
                        }
                    }

                    // Destination Folder
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Destination Folder")
                            .font(.headline)
                        HStack {
                            Text(destinationPath)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(nsColor: .controlBackgroundColor))
                                .cornerRadius(6)
                            Button("Choose…") { showFilePicker = true }
                        }
                    }

                    // Options
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Options")
                            .font(.headline)
                        Toggle("Embed Thumbnail", isOn: $embedThumbnail)
                        Toggle("Embed Metadata", isOn: $embedMetadata)
                        Toggle("Show Console Output", isOn: $showConsole)
                    }

                    // Download Button
                    Button(action: startDownload) {
                        HStack {
                            Image(systemName: downloadManager.isDownloading ? "stop.circle.fill" : "arrow.down.circle.fill")
                            Text(downloadManager.isDownloading ? "Cancel Download" : "Download")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(downloadManager.isDownloading ? Color.green : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(urlInput.isEmpty && !downloadManager.isDownloading)

                    // Progress + Show in Finder
                    if downloadManager.isDownloading || !downloadManager.lastStatus.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Status")
                                    .font(.headline)
                                Spacer()
                                if downloadManager.isDownloading {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                }
                            }
                            Text(downloadManager.lastStatus)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(
                                    downloadManager.isDownloading ? .primary :
                                        (downloadManager.lastStatus.hasPrefix("✓") ? .green : .red)
                                )
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(nsColor: .controlBackgroundColor))
                                .cornerRadius(6)

                            // Show in Finder — appears only after a successful download
                            if let folderURL = lastDownloadedFolderURL,
                               downloadManager.lastStatus.hasPrefix("✓") {
                                Button {
                                    NSWorkspace.shared.activateFileViewerSelecting([folderURL])
                                } label: {
                                    Label("Show in Finder", systemImage: "folder")
                                        .font(.subheadline)
                                }
                                .buttonStyle(.link)
                            }
                        }
                    }

                    // Console Output
                    if showConsole && !downloadManager.consoleOutput.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Console Output")
                                .font(.headline)
                            ScrollView {
                                ScrollViewReader { proxy in
                                    Text(downloadManager.consoleOutput)
                                        .font(.system(.caption, design: .monospaced))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(8)
                                        .id("console")
                                        .onChange(of: downloadManager.consoleOutput) { _, _ in
                                            proxy.scrollTo("console", anchor: .bottom)
                                        }
                                }
                            }
                            .frame(height: 200)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .cornerRadius(6)
                        }
                    }
                }
                .padding(20)
            }
        }
        .frame(minWidth: 600, minHeight: 500)
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                destinationPath = url.path
            }
        }
        .alert("Information", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - Actions

    func startDownload() {
        if downloadManager.isDownloading {
            downloadManager.cancelDownload()
            return
        }
        guard !urlInput.isEmpty else { return }

        lastDownloadedFolderURL = nil  // Clear previous result

        var options = DownloadOptions(
            url: urlInput,
            format: selectedFormat,
            destination: destinationPath,
            embedThumbnail: embedThumbnail,
            embedMetadata: embedMetadata,
            ytdlpPath: ytdlpPath,
            ffmpegPath: ffmpegPath
        )
        if useCustomFilename && !customFilename.isEmpty {
            options.customFilename = customFilename
        }

        downloadManager.onDownloadCompleted = { [self] folderURL in
            lastDownloadedFolderURL = folderURL
        }

        downloadManager.startDownload(options: options)
    }

    func autoDetectFFmpeg() {
        let commonPaths = [
            "/opt/homebrew/bin/ffmpeg",
            "/usr/local/bin/ffmpeg",
            "/opt/local/bin/ffmpeg",
            NSHomeDirectory() + "/.local/bin/ffmpeg",
            "/usr/bin/ffmpeg"
        ]
        for path in commonPaths {
            if FileManager.default.fileExists(atPath: path) {
                ffmpegPath = path
                alertMessage = "Found ffmpeg at:\n\(path)"
                showAlert = true
                return
            }
        }
        let task = Process()
        task.launchPath = "/usr/bin/which"
        task.arguments = ["ffmpeg"]
        let pipe = Pipe()
        task.standardOutput = pipe
        do {
            try task.run()
            task.waitUntilExit()
            if task.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !path.isEmpty {
                    ffmpegPath = path
                    alertMessage = "Found ffmpeg at:\n\(path)"
                    showAlert = true
                    return
                }
            }
        } catch {}
        alertMessage = "Could not auto-detect ffmpeg.\n\nInstall with:\nbrew install ffmpeg"
        showAlert = true
    }

    func autoDetectYTDLP() {
        let commonPaths = [
            "/opt/homebrew/bin/yt-dlp",
            "/usr/local/bin/yt-dlp",
            "/opt/local/bin/yt-dlp",
            NSHomeDirectory() + "/.local/bin/yt-dlp",
            "/usr/bin/yt-dlp"
        ]
        for path in commonPaths {
            if FileManager.default.fileExists(atPath: path) {
                ytdlpPath = path
                alertMessage = "Found yt-dlp at:\n\(path)"
                showAlert = true
                return
            }
        }
        let task = Process()
        task.launchPath = "/usr/bin/which"
        task.arguments = ["yt-dlp"]
        let pipe = Pipe()
        task.standardOutput = pipe
        do {
            try task.run()
            task.waitUntilExit()
            if task.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !path.isEmpty {
                    ytdlpPath = path
                    alertMessage = "Found yt-dlp at:\n\(path)"
                    showAlert = true
                    return
                }
            }
        } catch {}
        alertMessage = "Could not auto-detect yt-dlp.\n\nInstall with:\nbrew install yt-dlp"
        showAlert = true
    }

    func checkYTDLP() {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: ytdlpPath) else {
            alertMessage = "yt-dlp not found at:\n\(ytdlpPath)\n\nbrew install yt-dlp"
            showAlert = true
            return
        }
        guard fileManager.isExecutableFile(atPath: ytdlpPath) else {
            alertMessage = "yt-dlp not executable:\n\(ytdlpPath)\n\nchmod +x \(ytdlpPath)"
            showAlert = true
            return
        }
        let task = Process()
        task.executableURL = URL(fileURLWithPath: ytdlpPath)
        task.arguments = ["--version"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if task.terminationStatus == 0 {
                let version = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "unknown"
                alertMessage = "✓ yt-dlp is working!\n\nPath: \(ytdlpPath)\nVersion: \(version)"
            } else {
                let error = String(data: data, encoding: .utf8) ?? "Unknown error"
                alertMessage = "yt-dlp error:\n\(error)"
            }
        } catch {
            alertMessage = "Error running yt-dlp:\n\(error.localizedDescription)\n\nIf sandbox is enabled, remove it in:\nSigning & Capabilities → App Sandbox"
        }
        showAlert = true
    }
}

// MARK: - Models

enum DownloadFormat {
    case mp4Best, mp41080p, mp4720p, mp4480p, mp3, m4a

    var ytdlpFormat: String {
        switch self {
        case .mp4Best:  return "bv*[ext=mp4]+ba[ext=m4a]/b[ext=mp4]/bv*+ba/b"
        case .mp41080p: return "bv*[height<=1080][ext=mp4]+ba[ext=m4a]/b[height<=1080][ext=mp4]/bv*[height<=1080]+ba/b[height<=1080]"
        case .mp4720p:  return "bv*[height<=720][ext=mp4]+ba[ext=m4a]/b[height<=720][ext=mp4]/bv*[height<=720]+ba/b[height<=720]"
        case .mp4480p:  return "bv*[height<=480][ext=mp4]+ba[ext=m4a]/b[height<=480][ext=mp4]/bv*[height<=480]+ba/b[height<=480]"
        case .mp3:      return "ba/b"
        case .m4a:      return "ba[ext=m4a]/ba/b"
        }
    }

    var isAudioOnly: Bool { self == .mp3 || self == .m4a }
}

struct DownloadOptions {
    let url: String
    let format: DownloadFormat
    let destination: String
    let embedThumbnail: Bool
    let embedMetadata: Bool
    let ytdlpPath: String
    let ffmpegPath: String
    var customFilename: String?
}

// MARK: - DownloadManager

class DownloadManager: ObservableObject {
    @Published var isDownloading = false
    @Published var lastStatus = ""
    @Published var consoleOutput = ""

    var onDownloadCompleted: ((URL) -> Void)?

    private var currentTask: Process?
    private var destinationFolder: String = ""

    func startDownload(options: DownloadOptions) {
        isDownloading = true
        lastStatus = "Starting download…"
        consoleOutput = ""
        destinationFolder = options.destination

        let task = Process()
        task.executableURL = URL(fileURLWithPath: options.ytdlpPath)

        var args: [String] = []

        args.append(contentsOf: ["--ffmpeg-location", options.ffmpegPath])
        args.append(contentsOf: ["-f", options.format.ytdlpFormat])

        if !options.format.isAudioOnly {
            args.append(contentsOf: ["--merge-output-format", "mp4"])
        }

        if options.format.isAudioOnly {
            if options.format == .mp3 {
                args.append(contentsOf: ["-x", "--audio-format", "mp3", "--audio-quality", "0"])
            } else {
                args.append(contentsOf: ["-x", "--audio-format", "m4a", "--audio-quality", "0"])
            }
        }

        if options.embedThumbnail { args.append("--embed-thumbnail") }
        if options.embedMetadata  { args.append("--embed-metadata") }

        var outputTemplate = "\(options.destination)/"
        if let customName = options.customFilename, !customName.isEmpty {
            outputTemplate += "\(customName).%(ext)s"
        } else {
            outputTemplate += "%(title)s.%(ext)s"
        }
        args.append(contentsOf: ["-o", outputTemplate])

        args.append(contentsOf: ["--newline", "--no-warnings", "--progress", options.url])

        task.arguments = args

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if !data.isEmpty, let output = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self?.consoleOutput += output
                    self?.parseOutput(output)
                }
            }
        }

        task.terminationHandler = { [weak self] task in
            DispatchQueue.main.async {
                self?.isDownloading = false
                if task.terminationStatus == 0 {
                    self?.lastStatus = "✓ Download completed successfully!"
                    if let folder = self?.destinationFolder {
                        self?.onDownloadCompleted?(URL(fileURLWithPath: folder))
                    }
                } else if task.terminationReason == .exit && task.terminationStatus == 15 {
                    self?.lastStatus = "Download cancelled"
                } else {
                    self?.lastStatus = "✗ Download failed (exit code: \(task.terminationStatus))"
                }
            }
        }

        currentTask = task

        do {
            try task.run()
        } catch {
            isDownloading = false
            lastStatus = "Error: \(error.localizedDescription)"
            consoleOutput += "\nError launching yt-dlp: \(error.localizedDescription)\n"
        }
    }

    func cancelDownload() {
        currentTask?.terminate()
        currentTask = nil
    }

    private func parseOutput(_ output: String) {
        let lines = output.components(separatedBy: .newlines)
        for line in lines {
            if line.contains("[download]") {
                if line.contains("Destination:") {
                    lastStatus = "Downloading…"
                } else if line.contains("100%") {
                    lastStatus = "Processing…"
                } else if line.contains("%") {
                    let parts = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                    if let i = parts.firstIndex(where: { $0.hasSuffix("%") }) {
                        lastStatus = "Downloading: \(parts[i])"
                    }
                }
            } else if line.contains("[ExtractAudio]")  { lastStatus = "Extracting audio…" }
            else if line.contains("[EmbedThumbnail]") { lastStatus = "Embedding thumbnail…" }
            else if line.contains("[Metadata]")       { lastStatus = "Adding metadata…" }
            else if line.contains("ERROR")            { lastStatus = "Error: \(line)" }
        }
    }
}
