//
//  AIService.swift
//  Hello World
//
//  Created by mike on 04/07/2025.
//

import Foundation

public protocol AIServiceProtocol: ObservableObject, Sendable {
    var isLoading: Bool { get }
    var lastError: String? { get }
    
    func sendMessage(_ input: String) async -> String?
} 
