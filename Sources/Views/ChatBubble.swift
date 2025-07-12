//
//  ChatBubble.swift
//  Hello World
//
//  Created by mike on 04/07/2025.
//

import SwiftUI

public struct ChatBubble: View {
    let message: ChatMessage
    
    public init(message: ChatMessage) {
        self.message = message
    }
    
    public var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .textSelection(.enabled)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    Text(formatTimestamp(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    VStack(alignment: .leading, spacing: 8) {
                        // Main content
                        Text(message.content)
                            .textSelection(.enabled)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(NSColor.controlBackgroundColor))
                            .foregroundColor(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        
                        // Structured content (if available)
                        if message.hasStructuredContent {
                            VStack(alignment: .leading, spacing: 8) {
                                if message.hasMultipleBlocks {
                                    // Multiple code blocks with headers
                                    ForEach(message.extractedBlocks, id: \.type) { block in
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("\(block.type):")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .padding(.horizontal, 12)
                                            
                                            Text(block.content)
                                                .textSelection(.enabled)
                                                .font(.system(.caption, design: .monospaced))
                                                .padding(8)
                                                .background(Color.blue.opacity(0.1))
                                                .foregroundColor(.blue)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                                )
                                                .padding(.horizontal, 12)
                                        }
                                    }
                                } else if let extractedContent = message.extractedContent {
                                    // Single extracted content
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Extracted Content:")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal, 12)
                                        
                                        Text(extractedContent)
                                            .textSelection(.enabled)
                                            .font(.system(.caption, design: .monospaced))
                                            .padding(8)
                                            .background(Color.blue.opacity(0.1))
                                            .foregroundColor(.blue)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                            )
                                            .padding(.horizontal, 12)
                                    }
                                }
                            }
                        }
                    }
                    
                    Text(formatTimestamp(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
        }
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
} 
