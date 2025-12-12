import XCTest
@testable import Aclio

/// Unit tests for InputValidator
final class InputValidationTests: XCTestCase {
    
    // MARK: - Goal Validation Tests
    
    func testValidGoal_Success() {
        let result = InputValidator.validateGoal("Learn to play guitar")
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorMessage)
    }
    
    func testEmptyGoal_Fails() {
        let result = InputValidator.validateGoal("")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Please enter a goal")
    }
    
    func testWhitespaceOnlyGoal_Fails() {
        let result = InputValidator.validateGoal("   \n\t  ")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Please enter a goal")
    }
    
    func testShortGoal_Fails() {
        let result = InputValidator.validateGoal("Run")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Goal must be at least 5 characters")
    }
    
    func testLongGoal_Fails() {
        let longGoal = String(repeating: "a", count: 501)
        let result = InputValidator.validateGoal(longGoal)
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Goal must be less than 500 characters")
    }
    
    func testGoalWithExactMinLength_Success() {
        let result = InputValidator.validateGoal("12345")
        XCTAssertTrue(result.isValid)
    }
    
    func testGoalWithExactMaxLength_Success() {
        let maxGoal = String(repeating: "a", count: 500)
        let result = InputValidator.validateGoal(maxGoal)
        XCTAssertTrue(result.isValid)
    }
    
    func testGoalWithHarmfulContent_Fails() {
        let result = InputValidator.validateGoal("I want to kill myself")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Please enter a constructive goal")
    }
    
    // MARK: - Chat Message Validation Tests
    
    func testValidChatMessage_Success() {
        let result = InputValidator.validateChatMessage("How do I stay motivated?")
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorMessage)
    }
    
    func testEmptyChatMessage_Fails() {
        let result = InputValidator.validateChatMessage("")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Please enter a message")
    }
    
    func testLongChatMessage_Fails() {
        let longMessage = String(repeating: "a", count: 2001)
        let result = InputValidator.validateChatMessage(longMessage)
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Message must be less than 2000 characters")
    }
    
    // MARK: - Name Validation Tests
    
    func testValidName_Success() {
        let result = InputValidator.validateName("John Doe")
        XCTAssertTrue(result.isValid)
    }
    
    func testEmptyName_Fails() {
        let result = InputValidator.validateName("")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Please enter your name")
    }
    
    func testShortName_Fails() {
        let result = InputValidator.validateName("J")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Name must be at least 2 characters")
    }
    
    func testLongName_Fails() {
        let longName = String(repeating: "a", count: 51)
        let result = InputValidator.validateName(longName)
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Name must be less than 50 characters")
    }
    
    func testNameWithNumbers_Fails() {
        let result = InputValidator.validateName("John123")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Name can only contain letters, spaces, hyphens, and apostrophes")
    }
    
    func testNameWithHyphen_Success() {
        let result = InputValidator.validateName("Mary-Jane")
        XCTAssertTrue(result.isValid)
    }
    
    func testNameWithApostrophe_Success() {
        let result = InputValidator.validateName("O'Connor")
        XCTAssertTrue(result.isValid)
    }
    
    // MARK: - Age Validation Tests
    
    func testValidAge_Success() {
        let result = InputValidator.validateAge("25")
        XCTAssertTrue(result.isValid)
    }
    
    func testEmptyAge_Success() {
        // Age is optional
        let result = InputValidator.validateAge("")
        XCTAssertTrue(result.isValid)
    }
    
    func testNonNumericAge_Fails() {
        let result = InputValidator.validateAge("twenty")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Please enter a valid age")
    }
    
    func testTooYoungAge_Fails() {
        let result = InputValidator.validateAge("12")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "You must be at least 13 years old")
    }
    
    func testTooOldAge_Fails() {
        let result = InputValidator.validateAge("121")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Please enter a valid age")
    }
    
    func testMinimumAge_Success() {
        let result = InputValidator.validateAge("13")
        XCTAssertTrue(result.isValid)
    }
    
    func testMaximumAge_Success() {
        let result = InputValidator.validateAge("120")
        XCTAssertTrue(result.isValid)
    }
    
    // MARK: - Question Answer Validation Tests
    
    func testValidQuestionAnswer_Success() {
        let result = InputValidator.validateQuestionAnswer("I prefer mornings for exercise")
        XCTAssertTrue(result.isValid)
    }
    
    func testEmptyQuestionAnswer_Success() {
        // Answers are optional
        let result = InputValidator.validateQuestionAnswer("")
        XCTAssertTrue(result.isValid)
    }
    
    func testLongQuestionAnswer_Fails() {
        let longAnswer = String(repeating: "a", count: 1001)
        let result = InputValidator.validateQuestionAnswer(longAnswer)
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Answer must be less than 1000 characters")
    }
}

