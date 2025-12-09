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
            print("❌ API: Invalid URL for endpoint: \(endpoint)")
            throw ApiError.invalidURL
        }
        
        print("📡 API: \(method) \(endpoint)")
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60 // Increase timeout for AI responses
        
        if let body = body {
            guard JSONSerialization.isValidJSONObject(body) else {
                print("❌ API: Invalid JSON body")
                throw ApiError.serverError("Invalid request body")
            }
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            if let bodyString = String(data: request.httpBody!, encoding: .utf8) {
                print("📤 API Body: \(bodyString.prefix(200))...")
            }
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ API: No HTTP response")
            throw ApiError.noData
        }
        
        print("📥 API Status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode >= 400 {
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ API Error Response: \(responseString)")
            }
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw ApiError.serverError(errorResponse.error ?? errorResponse.message ?? "Server error")
            }
            throw ApiError.serverError("Request failed with status \(httpResponse.statusCode)")
        }
        
        do {
            let decoded = try JSONDecoder().decode(T.self, from: data)
            print("✅ API: Successfully decoded response")
            return decoded
        } catch let decodingError {
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ API Decoding error: \(decodingError)")
                print("📥 API Raw response: \(responseString.prefix(500))")
            }
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
            "message": message as Any,
            "goalName": (goal?.name ?? "General") as Any,
            "goalCategory": (goal?.category ?? "Personal") as Any,
            "chatHistory": Array(chatHistory.suffix(4)) as Any
        ]
        
        if let goal = goal {
            let stepsArray: [[String: Any]] = goal.steps.map { step in
                [
                    "id": step.id as Any,
                    "title": step.title as Any,
                    "description": step.description as Any
                ]
            }
            body["steps"] = stepsArray as Any
            body["completedSteps"] = goal.completedSteps as Any
        }
        
        if let profile = profile {
            let profileDict: [String: Any] = [
                "name": profile.name as Any,
                "age": profile.age as Any,
                "gender": (profile.gender?.rawValue ?? "") as Any
            ]
            body["profile"] = profileDict as Any
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard JSONSerialization.isValidJSONObject(body) else {
            throw ApiError.serverError("Invalid request body")
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
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
        let id: Int?
        let question: String
        let placeholder: String?
    }
}

struct ExpandStepResponse: Codable {
    let detailedGuide: String?
    let resources: [ExpandResource]?
    let tips: [String]?
    let searchQuery: String?
    
    // Convenience to get formatted content
    var content: String {
        var result = detailedGuide ?? ""
        
        if let tips = tips, !tips.isEmpty {
            result += "\n\n**Tips:**\n"
            for tip in tips {
                result += "• \(tip)\n"
            }
        }
        
        if let resources = resources, !resources.isEmpty {
            result += "\n**Resources:**\n"
            for resource in resources {
                result += "• \(resource.name)"
                if let cost = resource.cost {
                    result += " (\(cost))"
                }
                result += "\n"
            }
        }
        
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct ExpandResource: Codable {
    let name: String
    let type: String?
    let url: String?
    let cost: String?
}

struct DoItForMeResponse: Codable {
    let result: String?
    let content: String?
    
    var displayContent: String {
        result ?? content ?? ""
    }
}

