import Foundation

// MARK: - Validation Result
struct ValidationResult {
    let isValid: Bool
    let errorMessage: String?
    
    static let valid = ValidationResult(isValid: true, errorMessage: nil)
    
    static func invalid(_ message: String) -> ValidationResult {
        ValidationResult(isValid: false, errorMessage: message)
    }
}

// MARK: - Input Validator
enum InputValidator {
    
    // MARK: - Goal Validation
    
    static func validateGoal(_ input: String) -> ValidationResult {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            return .invalid("Please enter a goal")
        }
        
        if trimmed.count < 5 {
            return .invalid("Goal must be at least 5 characters")
        }
        
        if trimmed.count > 500 {
            return .invalid("Goal must be less than 500 characters")
        }
        
        // Check for potentially harmful content (basic client-side check)
        if containsHarmfulContent(trimmed) {
            return .invalid("Please enter a constructive goal")
        }
        
        return .valid
    }
    
    // MARK: - Chat Message Validation
    
    static func validateChatMessage(_ input: String) -> ValidationResult {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            return .invalid("Please enter a message")
        }
        
        if trimmed.count > 2000 {
            return .invalid("Message must be less than 2000 characters")
        }
        
        return .valid
    }
    
    // MARK: - Profile Name Validation
    
    static func validateName(_ input: String) -> ValidationResult {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            return .invalid("Please enter your name")
        }
        
        if trimmed.count < 2 {
            return .invalid("Name must be at least 2 characters")
        }
        
        if trimmed.count > 50 {
            return .invalid("Name must be less than 50 characters")
        }
        
        // Only allow letters, spaces, hyphens, and apostrophes
        let nameRegex = "^[a-zA-Z\\s'-]+$"
        if !trimmed.matches(nameRegex) {
            return .invalid("Name can only contain letters, spaces, hyphens, and apostrophes")
        }
        
        return .valid
    }
    
    // MARK: - Age Validation
    
    static func validateAge(_ input: String) -> ValidationResult {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            return .valid // Age is optional
        }
        
        guard let age = Int(trimmed) else {
            return .invalid("Please enter a valid age")
        }
        
        if age < 13 {
            return .invalid("You must be at least 13 years old")
        }
        
        if age > 120 {
            return .invalid("Please enter a valid age")
        }
        
        return .valid
    }
    
    // MARK: - Question Answer Validation
    
    static func validateQuestionAnswer(_ input: String) -> ValidationResult {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Answers are optional
        if trimmed.isEmpty {
            return .valid
        }
        
        if trimmed.count > 1000 {
            return .invalid("Answer must be less than 1000 characters")
        }
        
        return .valid
    }
    
    // MARK: - Helpers
    
    private static func containsHarmfulContent(_ text: String) -> Bool {
        let lowerText = text.lowercased()
        
        // Only block clearly harmful patterns
        let harmfulPatterns = [
            "kill myself",
            "kill someone",
            "hurt myself",
            "suicide",
            "self harm",
            "make a bomb",
            "build a weapon"
        ]
        
        return harmfulPatterns.contains { lowerText.contains($0) }
    }
}

// MARK: - String Extension for Regex Matching
private extension String {
    func matches(_ regex: String) -> Bool {
        return self.range(of: regex, options: .regularExpression) != nil
    }
}

// MARK: - Validated Input Protocol
protocol ValidatedInput {
    var validationResult: ValidationResult { get }
    var isValid: Bool { get }
}

extension ValidatedInput {
    var isValid: Bool {
        validationResult.isValid
    }
}

