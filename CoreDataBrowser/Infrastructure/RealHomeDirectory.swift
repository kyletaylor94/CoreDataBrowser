import Foundation

extension FileManager {
    /// The real, non-sandboxed home directory of the current user, obtained via the POSIX
    /// password database (`getpwuid`) instead of the sandbox-aware Foundation API.
    /// - Note: Use this instead of `homeDirectoryForCurrentUser` whenever resolving paths that
    ///   were granted through home-relative-path temporary exception entitlements
    ///   (e.g. `~/Library/Developer/CoreSimulator/`), since those are always relative to the
    ///   true user home directory, not the sandbox container.
    var realHomeDirectoryForCurrentUser: URL {
        if let passwdEntry = getpwuid(getuid()), let homeDirPointer = passwdEntry.pointee.pw_dir {
            let path = String(cString: homeDirPointer)
            return URL(fileURLWithPath: path, isDirectory: true)
        }
        return homeDirectoryForCurrentUser
    }
}
