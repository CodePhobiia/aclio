import Foundation

// MARK: - API Configuration
struct ApiConfig {
    static let baseURL = "https://aclio-production.up.railway.app/api"
}

// MARK: - API Errors
enum ApiError: LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case serverError(String)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .noData: return "No data received"
        case .decodingError: return "Failed to decode response"
        case .serverError(let message): return message
        case .networkError(let error): return error.localizedDescription
        }
    }
}

// MARK: - API Service
actor ApiService {
    static let shared = ApiService()
    
    private init() {}
    
    // MARK: - Generic Request Methods
    
    private func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: [String: Any]? = nil
    ) async throws -> T {
        guard let url = URL(string: "\(ApiConfig.baseURL)/\(endpoint)") else {
            throw ApiError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let body = body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ApiError.noData
        }
        
        if httpResponse.statusCode >= 400 {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw ApiError.serverError(errorResponse.error ?? errorResponse.message ?? "Server error")
            }
            throw ApiError.serverError("Request failed with status \(httpResponse.statusCode)")
        }
        
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw ApiError.decodingError
        }
    }
    
    // MARK: - Health Check
    
    func checkHealth() async -> Bool {
        do {
            let response: HealthResponse = try await request(endpoint: "health")
            return response.status == "ok" && response.apiKeyConfigured == true
        } catch {
            print("⚠️ Backend health check failed: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Generate Steps
    
    func generateSteps(
        goal: String,
        profile: UserProfile?,
        location: LocationData?,
        additionalContext: String?
    ) async throws -> GenerateStepsResponse {
        var body: [String: Any] = [
            "goal": goal,
            "categories": GoalCategories.all.joined(separator: ", ")
        ]
        
        if let profile = profile {
            body["profile"] = [
                "name": profile.name,
                "age": profile.age,
                "gender": profile.gender?.rawValue ?? ""
            ]
        }
        
        if let location = location {
            body["location"] = [
                "city": location.city ?? "",
                "country": location.country ?? ""
            ]
        }
        
        if let context = additionalContext, !context.isEmpty {
            body["additionalContext"] = context
        }
        
        return try await request(endpoint: "generate-steps", method: "POST", body: body)
    }
    
    // MARK: - Generate Questions
    
    func generateQuestions(
        goal: String,
        profile: UserProfile?
    ) async throws -> GenerateQuestionsResponse {
        var body: [String: Any] = ["goal": goal]
        
        if let profile = profile {
            body["profile"] = [
                "name": profile.name,
                "age": profile.age,
                "gender": profile.gender?.rawValue ?? ""
            ]
        }
        
        return try await request(endpoint: "generate-questions", method: "POST", body: body)
    }
    
    // MARK: - Expand Step
    
    func expandStep(
        step: Step,
        goalName: String,
        profile: UserProfile?
    ) async throws -> ExpandStepResponse {
        var body: [String: Any] = [
            "step": [
                "id": step.id,
                "title": step.title,
                "description": step.description
            ],
            "goal": goalName
        ]
        
        if let profile = profile {
            body["profile"] = [
                "name": profile.name,
                "age": profile.age,
                "gender": profile.gender?.rawValue ?? ""
            ]
        }
        
        return try await request(endpoint: "expand-step", method: "POST", body: body)
    }
    
    // MARK: - Do It For Me
    
    func doItForMe(
        step: Step,
        goalName: String,
        profile: UserProfile?
    ) async throws -> DoItForMeResponse {
        var body: [String: Any] = [
            "step": [
                "id": step.id,
                "title": step.title,
                "description": step.description
            ],
            "goal": goalName
        ]
        
        if let profile = profile {
            body["profile"] = [
                "name": profile.name,
                "age": profile.age,
                "gender": profile.gender?.rawValue ?? ""
            ]
        }
        
        return try await request(endpoint: "do-it-for-me", method: "POST", body: body)
    }
    
    // MARK: - Chat Stream (Talk to Aclio)
    
    func chatStream(
        message: String,
        goal: Goal?,
        chatHistory: [[String: String]],
        profile: UserProfile?,
        onChunk: @escaping (String) -> Void
    ) async throws {
        guard let url = URL(string: "\(ApiConfig.baseURL)/talk-to-aclio-stream") else {
            throw ApiError.invalidURL
        }
        
        var body: [String: Any] = [
            "message": message,
            "goalName": goal?.name ?? "General",
            "goalCategory": goal?.category ?? "Personal",
            "chatHistory": chatHistory.suffix(4)
        ]
        
        if let goal = goal {
            body["steps"] = goal.steps.map { [
                "id": $0.id,
                "title": $0.title,
                "description": $0.description
            ]}
            body["completedSteps"] = goal.completedSteps
        }
        
        if let profile = profile {
            body["profile"] = [
                "name": profile.name,
                "age": profile.age,
                "gender": profile.gender?.rawValue ?? ""
            ]
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ApiError.serverError("Chat request failed")
        }
        
        for try await line in bytes.lines {
            if line.hasPrefix("data: ") {
                let jsonString = String(line.dropFirst(6))
                if let data = jsonString.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let text = json["text"] as? String {
                        await MainActor.run {
                            onChunk(text)
                        }
                    }
                    if json["done"] as? Bool == true {
                        break
                    }
                    if let error = json["error"] as? String {
                        throw ApiError.serverError(error)
                    }
                }
            }
        }
    }
}

// MARK: - Response Models

struct HealthResponse: Codable {
    let status: String
    let apiKeyConfigured: Bool?
}

struct ErrorResponse: Codable {
    let error: String?
    let message: String?
}

struct GenerateStepsResponse: Codable {
    let steps: [ApiStep]
    let category: String?
    
    struct ApiStep: Codable {
        let id: Int
        let title: String
        let description: String
        let duration: String?
    }
    
    func toSteps() -> [Step] {
        steps.map { Step(id: $0.id, title: $0.title, description: $0.description, duration: $0.duration) }
    }
}

struct GenerateQuestionsResponse: Codable {
    let questions: [ApiQuestion]
    
    struct ApiQuestion: Codable {
        let id: String?
        let question: String
        let placeholder: String?
    }
}

struct ExpandStepResponse: Codable {
    let content: String
}

struct DoItForMeResponse: Codable {
    let result: String?
    let content: String?
    
    var displayContent: String {
        result ?? content ?? ""
    }
}

