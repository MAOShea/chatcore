//
//  AIService.swift
//  Hello World
//
//  Created by mike on 04/07/2025.
//

import Foundation
import FoundationModels

public class AIService: ObservableObject {
    @Published var isLoading = false
    @Published var lastError: String?
    
    private var session: LanguageModelSession?
    
    @MainActor
    func sendMessage(_ input: String) async -> String? {
        // Initialize session if needed
        if session == nil {
            do {
                session = LanguageModelSession()
                print("✅ LanguageModelSession created successfully")
            } catch {
                lastError = "Failed to create AI session: \(error.localizedDescription)"
                print("❌ Failed to create session: \(error)")
                return nil
            }
        }
        
        guard let session = session else {
            lastError = "Failed to create AI session"
            return nil
        }
        
        isLoading = true
        lastError = nil
        
        do {
            print("🤖 Sending message to AI: \(input)")
            let response = try await session.respond(to: input)
            isLoading = false
            print("✅ AI response received: \(response.content)")
            return response.content
        } catch {
            isLoading = false
            
            // Handle specific model availability error
            if let generationError = error as? LanguageModelSession.GenerationError {
                switch generationError {
                case .assetsUnavailable:
                    lastError = "AI model is not available. Please download the model in System Settings > AI."
                default:
                    lastError = "AI Error: \(generationError.localizedDescription)"
                }
            } else {
                lastError = "Failed to send message: \(error.localizedDescription)"
            }
            
            print("❌ AI Error: \(error)")
            print("❌ Error type: \(type(of: error))")
            print("❌ Error description: \(error.localizedDescription)")
            
            // Log more details for debugging content safety issues
            if error.localizedDescription.contains("unsafe") || error.localizedDescription.contains("content") {
                print("🔍 DEBUG: Potential content safety issue detected")
                print("🔍 DEBUG: Input that triggered error: \(input)")
                print("🔍 DEBUG: Full error details: \(error)")
            }
            
            return nil
        }
    }
} 
