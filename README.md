# CoreDataBrowser

## ✨ Overview

**CoreDataBrowser** is a lightweight macOS utility designed to help iOS developers inspect the local data used by apps running in the **iOS Simulator**.

During development it is often useful to quickly check what your app has stored locally. Instead of manually navigating through simulator directories, CoreDataBrowser provides a simple UI to explore that data.

With CoreDataBrowser you can inspect:

- **Core Data** SQLite databases
- **SwiftData** storage
- **UserDefaults** values

for any installed **iOS Simulator device**.

---

## 🚀 Features

- Browse installed **iOS Simulators**
- Inspect **Core Data databases**
- View **SwiftData storage**
- Read **UserDefaults values**
- Native **macOS UI**
- Simple and lightweight

---

## 📦 Installation

CoreDataBrowser can be installed using **Homebrew**.

### Open your terminal, and paste it:

```bash
brew tap kyletaylor94/apps && brew install --cask coredatabrowser
```
## OR 
```bash
brew tap kyletaylor94/apps && brew install coredatabrowser
```

## ⚠️ First Launch (Security Notice)
Since the app is not notarized by Apple, macOS may block it on the first launch.
To allow the app to run:
 - Open System Settings
 - navigate to Privacy & Security
 - scroll down to the Security section
 - you will see a message saying the app was blocked
 - click Open Anyway
 - after confirming this once, the app will launch normally.

---

## 🧑‍💻 Requirements

- **macOS**
- **Xcode** (required for iOS Simulators)

---

## 💡 Why this project?

While developing iOS applications it is often difficult to quickly inspect the local data used by the simulator.

**CoreDataBrowser** was created to provide a simple and convenient way to explore:

- **Core Data** databases  
- **SwiftData** storage  
- **UserDefaults** values  

without needing to manually locate simulator folders or write custom debugging scripts.
