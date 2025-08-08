//
//  ChatMessage.swift
//  Hello World
//
//  Created by mike on 04/07/2025.
//

import Foundation

public struct ChatMessage: Identifiable {
    public let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
    let structuredResponse: StructuredResponse?
    
    init(content: String, isUser: Bool, timestamp: Date = Date(), disableStructuredContent: Bool = false) {
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.structuredResponse = (isUser || disableStructuredContent) ? nil : StructuredResponse(from: content)
    }
    
    var hasStructuredContent: Bool {
        structuredResponse?.hasStructuredContent ?? false
    }
    
    var extractedContent: String? {
        structuredResponse?.extractedContent
    }
    
    var extractedBlocks: [StructuredResponse.CodeBlock] {
        structuredResponse?.extractedBlocks ?? []
    }
    
    var hasMultipleBlocks: Bool {
        extractedBlocks.count > 1
    }
} 
