//
//  ChatViewModel.swift
//  Hello World
//
//  Created by mike on 04/07/2025.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

@MainActor
public class ChatViewModel: ObservableObject {
    @Published public var conversationHistory: [ChatMessage] = []
    @Published public var userInput: String = ""
    @Published public var showingAlert = false
    @Published public var isLoading = false
    @Published public var lastError: String?
    @Published public var useStructuredOutput = false
    @Published public var promptStrategy = "Standard"
    @Published var isBootedUp = false
    @Published public var showingSaveDialog = false
    @Published public var javascriptToSave: String = ""
    
    private let aiService: any AIServiceProtocol
    private var lastSuccessfulSavePath: String?
    private let disableToolCallDetection: Bool
    private let disableStructuredContent: Bool
    
    // MARK: - Widget State Management
    
    /// Current widget code/state
    @Published var currentWidgetCode: String = ""
    
    public init(aiService: any AIServiceProtocol, disableToolCallDetection: Bool = false, disableStructuredContent: Bool = false) {
        self.aiService = aiService
        self.disableToolCallDetection = disableToolCallDetection
        self.disableStructuredContent = disableStructuredContent
    }
    
    public init() {
        // Default initializer - will be removed once apps are updated
        fatalError("Please use init(aiService:) instead")
    }
    
    /// Track if we have a current widget
    var hasCurrentWidget: Bool {
        !currentWidgetCode.isEmpty
    }
    
    public func bootUpWithRole(firstPrompt: String) {
        print("🚀 ChatViewModel: Booting up chat with widget designer role")
        
 
        // Add the role message to history - DEFER THIS UPDATE
        let roleMessage = ChatMessage(
            content: firstPrompt,
            isUser: true,
            timestamp: Date())
        DispatchQueue.main.async {
            self.conversationHistory.append(roleMessage)
        }
        
        // Send the role prompt to AI
        Task {
            await sendToAI(firstPrompt)
        }
        
        isBootedUp = true
    }
    
    public func sendMessage() {
        print("🔧 DEBUG: sendMessage called (regular mode)")
        print("🔧 DEBUG: useStructuredOutput = \(useStructuredOutput)")
        
        let trimmedInput = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else { return }
        
        // Add user message to history and clear input
        let userMessage = ChatMessage(content: trimmedInput, isUser: true, timestamp: Date())
        print("🔧 DEBUG: About to modify conversationHistory (sendMessage)")
        DispatchQueue.main.async {
            self.conversationHistory.append(userMessage)
            self.userInput = ""
        }
        
        // Send to AI
        Task {
            await sendToAI(trimmedInput)
        }
    }
    
    public func sendStructuredMessage(_ basePrompt: String) {
        print("🔧 DEBUG: sendStructuredMessage called")
        print("🔧 DEBUG: promptStrategy = \(promptStrategy)")
        
        // Hardcoded concatenation for HTML + CSS
        let enhancedPrompt = basePrompt + " include the HTML followed by the CSS."
        
        let structuredPrompt: String
        
        switch promptStrategy {
        case "Direct":
            structuredPrompt = StructuredResponse.createDirectStructuredPrompt(enhancedPrompt, outputType: "HTML")
        case "Role-based":
            structuredPrompt = StructuredResponse.createRoleBasedPrompt(enhancedPrompt, outputType: "HTML")
        case "Markdown":
            structuredPrompt = StructuredResponse.createMarkdownFriendlyPrompt(enhancedPrompt, outputType: "HTML")
        default:
            structuredPrompt = StructuredResponse.createStructuredPrompt(enhancedPrompt, outputType: "HTML")
        }
        
        // Debug: Log what we're sending to AI
        print("🎯 DEBUG: Structured prompt being sent to AI:")
        print("---START OF PROMPT---")
        print(structuredPrompt)
        print("---END OF PROMPT---")
        
        // Add user message to history (show original prompt, not enhanced)
        let userMessage = ChatMessage(content: basePrompt, isUser: true, timestamp: Date())
        print("🔧 DEBUG: About to modify conversationHistory (sendStructuredMessage)")
        conversationHistory.append(userMessage)
        
        // Send structured prompt to AI with context management
        Task {
            await sendToAI(structuredPrompt)
        }
    }
    

    
    private func checkAndGenerateWidgetFile(from response: String) async {
        if disableStructuredContent {
            print("🔍 ChatViewModel: Structured content disabled, skipping JavaScript block detection")
            return
        }
        
        print("🔍 ChatViewModel: Checking for JavaScript blocks in response")
        
        let structuredResponse = StructuredResponse(from: response)
        let blocks = structuredResponse.extractedBlocks
        
        // Look for JavaScript blocks
        let jsBlock = blocks.first { $0.type.lowercased().contains("javascript") || $0.type.lowercased().contains("js") }
        
        if let js = jsBlock {
            print("🎯 ChatViewModel: Found JavaScript block, generating widget file")
            await generateWidgetFile(javascript: js.content)
        } else {
            print("🔍 ChatViewModel: JavaScript block not found in response")
        }
    }
    
    private func checkForToolCall(from response: String) async {
        if disableToolCallDetection {
            print("🔍 ChatViewModel: Tool call detection disabled, skipping")
            return
        }
        
        print("🔍 ChatViewModel: Checking for tool call in response")
        
        // Check if the response indicates a tool was called
        if response.contains("widget") && (response.contains("created") || response.contains("generated")) {
            print("🎯 ChatViewModel: Detected tool call, showing save dialog")
            await showToolGeneratedFile()
        } else {
            print("🔍 ChatViewModel: No tool call detected in response")
        }
    }
    
    private func showToolGeneratedFile() async {
        print("📝 ChatViewModel: Showing save dialog for tool-generated file")
        
        // For now, we'll show a placeholder - the actual JSX content would need to be passed from the tool
        let placeholderJSX = """
        // Tool-generated Übersicht widget
        // This is a placeholder - the actual JSX content should come from the tool
        import { css } from 'uebersicht';
        
        const widget = () => {
            return (
                <div>
                    <h1>Hello World</h1>
                </div>
            );
        };
        
        export default widget;
        """
        
        await MainActor.run {
            self.javascriptToSave = placeholderJSX
            self.currentWidgetCode = placeholderJSX
            self.showingSaveDialog = true
        }
    }
    
    private func generateWidgetFile(javascript: String) async {
        print("📝 ChatViewModel: Generating widget file")
        print("📝 ChatViewModel: JavaScript content length: \(javascript.count)")
        print("📝 ChatViewModel: JavaScript content preview: \(String(javascript.prefix(100)))...")
        
        // Store the JavaScript content and show save dialog
        await MainActor.run {
            self.javascriptToSave = javascript
            self.currentWidgetCode = javascript  // Store as current widget state
            self.showingSaveDialog = true
        }
    }
    
    public func saveWidgetFile() {
        print("🔧 DEBUG: saveWidgetFile called")
        // Always show the file picker - no automatic fallback
        showFilePicker()
    }
    
    private func showFilePicker() {
        print("🔧 DEBUG: showFilePicker called")
        let savePanel = NSSavePanel()
        savePanel.title = "Save Widget File"
        savePanel.nameFieldStringValue = "index.jsx"
        savePanel.allowedContentTypes = [UTType(filenameExtension: "jsx")!]
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        
        // Set the initial directory to Übersicht widgets folder
        let übersichtWidgetsPath = "\(NSHomeDirectory())/Library/Application Support/Übersicht/widgets"
        savePanel.directoryURL = URL(fileURLWithPath: übersichtWidgetsPath)
        
        // Get the current window to present the save panel
        guard let window = NSApplication.shared.windows.first else {
            print("❌ ChatViewModel: No window available to present save panel")
            return
        }
        
        print("🔧 DEBUG: Found window: \(window.title)")
                        print("🔧 DEBUG: About to present save panel")
                let javascriptContent = javascriptToSave
                print("🔧 DEBUG: JavaScript content length: \(javascriptContent.count)")
                print("🔧 DEBUG: Calling beginSheetModal...")
                savePanel.beginSheetModal(for: window) { [weak self] response in
            print("🔧 DEBUG: Save panel response received: \(response.rawValue)")
            guard let self = self else { return }
            if response == .OK {
                DispatchQueue.main.async {
                    guard let saveURL = savePanel.url else { return }
                    do {
                        try javascriptContent.write(to: saveURL, atomically: true, encoding: .utf8)
                        print("✅ ChatViewModel: Widget file saved successfully!")
                        print("📁 File location: \(saveURL.path)")
                        
                        // Remember this successful path for future saves
                        self.lastSuccessfulSavePath = saveURL.path
                        
                        // Success - no need to show alert
                        self.lastError = nil
                        self.showingAlert = false
                    } catch {
                        print("❌ ChatViewModel: Failed to save widget file: \(error)")
                        print("❌ ChatViewModel: Error details: \(error.localizedDescription)")
                        
                        // Show error message
                        self.lastError = "Failed to save file: \(error.localizedDescription)"
                        self.showingAlert = true
                    }
                }
            }
        }
    }
    
    public func clearConversation() {
        conversationHistory.removeAll()
        currentWidgetCode = ""  // Clear widget state
        isBootedUp = false
    }
    

    
    /// Send message to AI (simplified - no context management)
    private func sendToAI(_ input: String) async {
        print("🔄 ChatViewModel: Starting AI request")
        print("🔧 DEBUG: About to modify isLoading (sendToAI start)")
        DispatchQueue.main.async {
            self.isLoading = true
            self.lastError = nil
        }
        
        if let response = await aiService.sendMessage(input) {
            print("✅ ChatViewModel: AI response received, adding to conversation")
            let aiMessage = ChatMessage(content: response, isUser: false, timestamp: Date(), disableStructuredContent: disableStructuredContent)
            print("🔧 DEBUG: About to modify conversationHistory (sendToAI success)")
            DispatchQueue.main.async {
                self.conversationHistory.append(aiMessage)
            }
            
            // Log structured content if found
            if !disableStructuredContent {
                if aiMessage.hasStructuredContent {
                    print("🎯 ChatViewModel: Found structured content: \(aiMessage.extractedContent ?? "nil")")
                }
            }
            
            // Check if we should generate widget file
            await checkAndGenerateWidgetFile(from: response)
            
            // Check if a tool was called (for tool-based file generation)
            await checkForToolCall(from: response)
            
            print("📝 ChatViewModel: Conversation history now has \(conversationHistory.count) messages")
        } else {
            print("❌ ChatViewModel: AI request failed")
            let errorMessage = ChatMessage(
                content: "Error: \(aiService.lastError ?? "Unknown error")",
                isUser: false,
                timestamp: Date()
            )
            print("🔧 DEBUG: About to modify conversationHistory (sendToAI error)")
            DispatchQueue.main.async {
                self.conversationHistory.append(errorMessage)
            }
        }
        
        print("🔧 DEBUG: About to modify isLoading (sendToAI end)")
        DispatchQueue.main.async {
            self.isLoading = false
        }
        print("🔄 ChatViewModel: AI request completed")
    }
} 
