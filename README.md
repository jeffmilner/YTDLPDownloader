# yt-dlp GUI Downloader

A sleek, lightweight macOS frontend for `yt-dlp` built with **SwiftUI**. This application provides a user-friendly interface to download videos and audio from over 1,000 supported websites without needing to touch the terminal.

## 🚀 Features

* **Format Selection**: Choose between high-quality MP4 (up to 1080p) or audio-only formats (MP3/M4A).
* **Customization**: Options to use custom filenames, embed thumbnails, and include metadata automatically.
* **Auto-Detection**: Built-in logic to find your `yt-dlp` and `ffmpeg` installations (Homebrew, `/usr/local/bin`, etc.).
* **Real-time Feedback**: Includes a live status indicator and a togglable console output to monitor download progress.
* **Finder Integration**: Open the destination folder directly from the app once a download completes.
* **Native Design**: A clean, modern macOS interface with support for both Light and Dark modes.

## 🛠 Prerequisites

This app acts as a GUI wrapper, so you must have the following command-line tools installed on your Mac:

1.  **yt-dlp**: The core engine for downloading.
2.  **ffmpeg**: Required for merging video and audio streams or converting formats.

### Installation via Homebrew
If you don't have them yet, the easiest way to install them is via [Homebrew](https://brew.sh):
```bash
brew install yt-dlp ffmpeg
```

## ⚙️ Setup

1.  **Clone or Download** the source code into an Xcode project.
2.  **Disable App Sandbox**: Since this app executes external binaries (`yt-dlp` and `ffmpeg`), you may need to disable the App Sandbox in the **Signing & Capabilities** tab of your Xcode target.
3.  **Configure Paths**: On the first launch, click the **Gear icon** to open Settings. Use the **Auto-detect** buttons to link the app to your local installations of `yt-dlp` and `ffmpeg`.

## 📖 How to Use

1.  **Paste a URL**: Enter the link to the video you wish to download.
2.  **Select Format**: Choose your preferred quality or audio format.
3.  **Pick Destination**: Select where you want the file saved (defaults to your Downloads folder).
4.  **Download**: Hit the download button and watch the status update in real-time.

---

## 🏗 Technical Details

* **Language**: Swift 5.10+
* **Framework**: SwiftUI
* **Execution**: Uses `Foundation.Process` to bridge with shell commands.
* **State Management**: Utilizes `@StateObject` and `@AppStorage` for persistent settings and reactive UI updates.

## 📄 License
This project is open-source. Feel free to modify and distribute as needed.
