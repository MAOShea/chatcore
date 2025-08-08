//
//  FilePickerUtility.swift
//  ChatCore
//
//  Created by mike on 04/07/2025.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

public class FilePickerUtility {
    
    /// Remember the last successful save path (thread-safe)
    @MainActor
    private static var lastSuccessfulSavePath: String?
    
    /// Remember the last successful directory path (thread-safe)
    @MainActor
    private static var lastSuccessfulDirectoryPath: String?
    
    /// Save content to a file using a file picker dialog
    /// - Parameters:
    ///   - content: The content to save
    ///   - defaultName: Default filename (without extension)
    ///   - fileExtension: File extension (e.g., "jsx")
    ///   - initialDirectory: Initial directory path for the file picker
    /// - Returns: The path where the file was saved, or nil if cancelled/failed
    public static func saveFile(
        content: String,
        defaultName: String = "index",
        fileExtension: String = "jsx",
        initialDirectory: String? = nil
    ) async -> String? {
        
        print("🔧 DEBUG: FilePickerUtility.saveFile called")
        
        // Try to save to the last successful path first
        let savedPath = await MainActor.run { () -> String? in
            if let lastPath = lastSuccessfulSavePath {
                let lastURL = URL(fileURLWithPath: lastPath)
                do {
                    try content.write(to: lastURL, atomically: true, encoding: .utf8)
                    print("✅ FilePickerUtility: File saved successfully using previous path!")
                    print("📁 FilePickerUtility: File location: \(lastPath)")
                    return lastPath
                } catch {
                    print("⚠️ FilePickerUtility: Previous path save failed: \(error)")
                    // Fall through to file picker
                }
            }
            return nil
        }
        
        if let path = savedPath {
            return path
        }
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let savePanel = NSSavePanel()
                savePanel.title = "Save File"
                savePanel.nameFieldStringValue = "\(defaultName).\(fileExtension)"
                let contentType = UTType(filenameExtension: fileExtension) ?? UTType.plainText
                savePanel.allowedContentTypes = [contentType]
                savePanel.canCreateDirectories = true
                savePanel.isExtensionHidden = true
                
                // Set the initial directory if provided
                if let initialDirectory = initialDirectory {
                    savePanel.directoryURL = URL(fileURLWithPath: initialDirectory)
                }
                
                // Get the current window to present the save panel
                guard let window = NSApplication.shared.windows.first else {
                    print("❌ FilePickerUtility: No window available to present save panel")
                    continuation.resume(returning: nil)
                    return
                }
                
                print("🔧 DEBUG: FilePickerUtility: Found window: \(window.title)")
                print("🔧 DEBUG: FilePickerUtility: About to present save panel")
                print("🔧 DEBUG: FilePickerUtility: Content length: \(content.count)")
                
                savePanel.beginSheetModal(for: window) { response in
                    print("🔧 DEBUG: FilePickerUtility: Save panel response received: \(response.rawValue)")
                    
                    if response == .OK {
                        DispatchQueue.main.async {
                            guard let saveURL = savePanel.url else {
                                print("❌ FilePickerUtility: No save URL provided")
                                continuation.resume(returning: nil)
                                return
                            }
                            
                            let urlPath = saveURL.path
                            
                            do {
                                try content.write(to: saveURL, atomically: true, encoding: .utf8)
                                print("✅ FilePickerUtility: File saved successfully!")
                                print("📁 FilePickerUtility: File location: \(urlPath)")
                                
                                // Remember this successful path for future saves
                                lastSuccessfulSavePath = urlPath
                                
                                continuation.resume(returning: urlPath)
                            } catch {
                                print("❌ FilePickerUtility: Failed to save file: \(error)")
                                print("❌ FilePickerUtility: Error details: \(error.localizedDescription)")
                                continuation.resume(returning: nil)
                            }
                        }
                    } else {
                        print("❌ FilePickerUtility: File save cancelled by user")
                        continuation.resume(returning: nil)
                    }
                }
            }
        }
    }
    
    /// Pick a directory using a folder picker dialog
    /// - Parameters:
    ///   - initialDirectory: Initial directory path for the folder picker
    /// - Returns: The path of the selected directory, or nil if cancelled/failed
    public static func pickDirectory(
        initialDirectory: String? = nil
    ) async -> String? {
        
        print("🔧 DEBUG: FilePickerUtility.pickDirectory called")
        
        // Try to use the last successful directory first
        let directoryPath = await MainActor.run { () -> String? in
            if let lastPath = lastSuccessfulDirectoryPath {
                print("✅ FilePickerUtility: Using previous directory path!")
                print("📁 FilePickerUtility: Directory location: \(lastPath)")
                return lastPath
            }
            return nil
        }
        
        if let path = directoryPath {
            return path
        }
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let openPanel = NSOpenPanel()
                openPanel.title = "Choose Widget Directory"
                openPanel.message = "Select a folder to save your widget"
                openPanel.prompt = "Choose"
                openPanel.canChooseFiles = false
                openPanel.canChooseDirectories = true
                openPanel.allowsMultipleSelection = false
                openPanel.canCreateDirectories = true
                
                // Set the initial directory if provided
                if let initialDirectory = initialDirectory {
                    openPanel.directoryURL = URL(fileURLWithPath: initialDirectory)
                }
                
                // Get the current window to present the open panel
                guard let window = NSApplication.shared.windows.first else {
                    print("❌ FilePickerUtility: No window available to present directory picker")
                    continuation.resume(returning: nil)
                    return
                }
                
                print("🔧 DEBUG: FilePickerUtility: Found window: \(window.title)")
                print("🔧 DEBUG: FilePickerUtility: About to present directory picker")
                
                openPanel.beginSheetModal(for: window) { response in
                    print("🔧 DEBUG: FilePickerUtility: Directory picker response received: \(response.rawValue)")
                    
                    if response == .OK {
                        DispatchQueue.main.async {
                            guard let selectedURL = openPanel.url else {
                                print("❌ FilePickerUtility: No directory URL provided")
                                continuation.resume(returning: nil)
                                return
                            }
                            
                            let urlPath = selectedURL.path
                            
                            print("✅ FilePickerUtility: Directory selected successfully!")
                            print("📁 FilePickerUtility: Directory location: \(urlPath)")
                            
                            // Remember this successful directory for future picks
                            lastSuccessfulDirectoryPath = urlPath
                            
                            continuation.resume(returning: urlPath)
                        }
                    } else {
                        print("❌ FilePickerUtility: Directory picker cancelled by user")
                        continuation.resume(returning: nil)
                    }
                }
            }
        }
    }
} 