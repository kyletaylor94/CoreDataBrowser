//
//  RealHomeDirectory.swift
//  CoreDataBrowser
//
//  Provides access to the user's REAL home directory, bypassing the
//  App Sandbox container redirection that `FileManager.homeDirectoryForCurrentUser`
//  (and `NSHomeDirectory()`) are subject to.
//
//  Under App Sandbox, `homeDirectoryForCurrentUser` returns the sandbox container's
//  virtualized home (e.g. `~/Library/Containers/<bundle-id>/Data/`) instead of the
//  actual user home (`/Users/<username>`). This breaks any code that resolves
//  home-relative paths granted via `com.apple.security.temporary-exception.files.home-relative-path.*`
//  entitlements, since those exceptions are relative to the REAL home directory.
//

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
