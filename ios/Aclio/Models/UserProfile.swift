import Foundation

// MARK: - User Profile Model
struct UserProfile: Codable, Equatable {
    var name: String
    var age: String
    var gender: Gender?
    
    init(name: String = "", age: String = "", gender: Gender? = nil) {
        self.name = name
        self.age = age
        self.gender = gender
    }
    
    var isEmpty: Bool {
        name.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var displayName: String {
        name.trimmingCharacters(in: .whitespaces).isEmpty ? "Achiever" : name
    }
    
    var ageInt: Int? {
        Int(age)
    }
}

// MARK: - Gender Enum
enum Gender: String, Codable, CaseIterable {
    case male = "Male"
    case female = "Female"
    case other = "Other"
    
    var displayName: String { rawValue }
}

// MARK: - Location Data
struct LocationData: Codable, Equatable {
    let latitude: Double
    let longitude: Double
    var city: String?
    var country: String?
    var displayName: String?
    
    var shortDisplay: String {
        city ?? "Location enabled"
    }
}

// MARK: - Greeting Helper
extension UserProfile {
    static func greeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        if hour < 12 {
            return "Good morning"
        } else if hour < 18 {
            return "Good afternoon"
        } else {
            return "Good evening"
        }
    }
}

// MARK: - Sample Data
extension UserProfile {
    static let sample = UserProfile(name: "Theyab", age: "22", gender: .male)
    static let empty = UserProfile()
}

