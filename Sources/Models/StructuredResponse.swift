//
//  StructuredResponse.swift
//  Hello World
//
//  Created by mike on 04/07/2025.
//

import Foundation

public struct StructuredResponse {
    static let startMarker = "@@>>>@@@"
    static let endMarker = "@@@<<<@@@"
    
    let rawResponse: String
    let extractedContent: String?
    let hasStructuredContent: Bool
    let extractedBlocks: [CodeBlock]
    
    struct CodeBlock {
        let type: String
        let content: String
    }
    
    init(from response: String) {
        self.rawResponse = response
        
        // Extract plain markdown code blocks
        self.extractedBlocks = StructuredResponse.extractPlainCodeBlocks(from: response)
        
        // First try to extract content between our custom markers
        if let customContent = StructuredResponse.extractCustomMarkers(from: response) {
            self.extractedContent = customContent
            self.hasStructuredContent = true
            return
        }
        
        // If custom markers fail, try to extract from markdown code blocks
        if let markdownContent = StructuredResponse.extractMarkdownCodeBlock(from: response) {
            self.extractedContent = markdownContent
            self.hasStructuredContent = true
            return
        }
        
        // No structured content found
        self.extractedContent = nil
        self.hasStructuredContent = false
    }
    
    private static func extractCustomMarkers(from response: String) -> String? {
        guard let startRange = response.range(of: StructuredResponse.startMarker),
              let endRange = response.range(of: StructuredResponse.endMarker) else {
            return nil
        }
        
        let startIndex = startRange.upperBound
        let endIndex = endRange.lowerBound
        
        guard startIndex < endIndex else { return nil }
        
        return String(response[startIndex..<endIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private static func extractMarkdownCodeBlock(from response: String) -> String? {
        print("🔍 DEBUG: Attempting to extract markdown code block")
        print("🔍 DEBUG: Response length: \(response.count)")
        
        // Look for ```json, ```xml, ```csv, ```swift, etc.
        let codeBlockPattern = #"```(?:json|xml|csv|swift|javascript|python|html|css|yaml|toml|ini|sql|bash|shell|markdown|text)?\s*\n(.*?)\n```"#
        
        guard let regex = try? NSRegularExpression(pattern: codeBlockPattern, options: [.dotMatchesLineSeparators]) else {
            print("🔍 DEBUG: Failed to create regex")
            return nil
        }
        
        let range = NSRange(response.startIndex..<response.endIndex, in: response)
        let matches = regex.matches(in: response, options: [], range: range)
        
        print("🔍 DEBUG: Found \(matches.count) code block matches")
        
        // Return the content of the first code block found
        if let firstMatch = matches.first,
           let range = Range(firstMatch.range(at: 1), in: response) {
            let extracted = String(response[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            print("🔍 DEBUG: Extracted content: \(extracted)")
            return extracted
        }
        
        print("🔍 DEBUG: No valid code block content found")
        return nil
    }
    

    
    private static func extractPlainCodeBlocks(from response: String) -> [CodeBlock] {
        print("🔍 DEBUG: Attempting to extract plain code blocks")
        
        // Pattern to match: ```type content```
        let pattern = #"```(\w+)\s*\n(.*?)\n```"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
            print("🔍 DEBUG: Failed to create regex for plain code blocks")
            return []
        }
        
        let range = NSRange(response.startIndex..<response.endIndex, in: response)
        let matches = regex.matches(in: response, options: [], range: range)
        
        print("🔍 DEBUG: Found \(matches.count) plain code blocks")
        
        var blocks: [CodeBlock] = []
        
        for match in matches {
            if let codeTypeRange = Range(match.range(at: 1), in: response),
               let contentRange = Range(match.range(at: 2), in: response) {
                
                let codeType = String(response[codeTypeRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                let content = String(response[contentRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                
                let block = CodeBlock(type: codeType, content: content)
                blocks.append(block)
                
                print("🔍 DEBUG: Extracted plain block - CodeType: \(codeType), Content length: \(content.count)")
            }
        }
        
        return blocks
    }
    
    // Helper to create prompts that request structured output
    static func createStructuredPrompt(_ basePrompt: String, outputType: String) -> String {
        return """
        \(basePrompt)
        
        Please provide your response in a \(outputType) code block format like this:
        ```\(outputType.lowercased())
        [your \(outputType) content here]
        ```
        
        Make sure the \(outputType) content is properly formatted and valid.
        """
    }
    
    // Alternative strategy: More direct approach
    static func createDirectStructuredPrompt(_ basePrompt: String, outputType: String) -> String {
        return """
        \(basePrompt)
        
        Respond with ONLY the \(outputType) content in a code block:
        ```\(outputType.lowercased())
        [your \(outputType) content here]
        ```
        
        Do not include any other text or explanations.
        """
    }
    
    // Alternative strategy: Role-based approach
    static func createRoleBasedPrompt(_ basePrompt: String, outputType: String) -> String {
        return """
        You are a \(outputType) generator. Your task is to generate \(outputType) content.
        
        \(basePrompt)
        
        Format your response as a \(outputType) code block:
        ```\(outputType.lowercased())
        [your \(outputType) content here]
        ```
        
        Make sure the content is properly formatted and valid.
        """
    }
    
    // Fallback strategy: Work with AI's natural markdown tendencies
    static func createMarkdownFriendlyPrompt(_ basePrompt: String, outputType: String) -> String {
        return """
        \(basePrompt)
        
        Please provide your response in a \(outputType) code block format like this:
        ```\(outputType.lowercased())
        [your \(outputType) content here]
        ```
        
        Make sure the \(outputType) content is properly formatted and valid.
        """
    }
} 
