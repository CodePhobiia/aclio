import XCTest
@testable import Aclio

/// Unit tests for PremiumService feature gating logic
/// Note: These tests focus on the business logic, not RevenueCat integration
final class PremiumServiceTests: XCTestCase {
    
    var service: PremiumService!
    
    override func setUp() {
        super.setUp()
        service = PremiumService.shared
        // Start with non-premium state for consistent tests
        service.clearPremiumStatus()
    }
    
    override func tearDown() {
        service.clearPremiumStatus()
        super.tearDown()
    }
    
    // MARK: - Goal Creation Tests
    
    func testCanCreateGoal_FreeUser_UnderLimit() {
        // Given: Free user with 2 goals (under limit of 3)
        service.setPremium(false)
        
        // When
        let canCreate = service.canCreateGoal(currentCount: 2)
        
        // Then
        XCTAssertTrue(canCreate, "Free user should be able to create goal when under limit")
    }
    
    func testCanCreateGoal_FreeUser_AtLimit() {
        // Given: Free user at the goal limit
        service.setPremium(false)
        
        // When
        let canCreate = service.canCreateGoal(currentCount: PremiumConfig.freeGoalLimit)
        
        // Then
        XCTAssertFalse(canCreate, "Free user should not create goal when at limit")
    }
    
    func testCanCreateGoal_FreeUser_OverLimit() {
        // Given: Free user over the limit (shouldn't happen, but test edge case)
        service.setPremium(false)
        
        // When
        let canCreate = service.canCreateGoal(currentCount: PremiumConfig.freeGoalLimit + 1)
        
        // Then
        XCTAssertFalse(canCreate, "Free user should not create goal when over limit")
    }
    
    func testCanCreateGoal_PremiumUser_Unlimited() {
        // Given: Premium user
        service.setPremium(true)
        
        // When
        let canCreate = service.canCreateGoal(currentCount: 100)
        
        // Then
        XCTAssertTrue(canCreate, "Premium user should always be able to create goals")
    }
    
    // MARK: - Goals Remaining Tests
    
    func testGoalsRemaining_FreeUser_NoGoals() {
        // Given
        service.setPremium(false)
        
        // When
        let remaining = service.getGoalsRemaining(currentCount: 0)
        
        // Then
        XCTAssertEqual(remaining, PremiumConfig.freeGoalLimit)
    }
    
    func testGoalsRemaining_FreeUser_SomeGoals() {
        // Given
        service.setPremium(false)
        
        // When
        let remaining = service.getGoalsRemaining(currentCount: 1)
        
        // Then
        XCTAssertEqual(remaining, PremiumConfig.freeGoalLimit - 1)
    }
    
    func testGoalsRemaining_FreeUser_AtLimit() {
        // Given
        service.setPremium(false)
        
        // When
        let remaining = service.getGoalsRemaining(currentCount: PremiumConfig.freeGoalLimit)
        
        // Then
        XCTAssertEqual(remaining, 0)
    }
    
    func testGoalsRemaining_PremiumUser() {
        // Given
        service.setPremium(true)
        
        // When
        let remaining = service.getGoalsRemaining(currentCount: 50)
        
        // Then
        XCTAssertEqual(remaining, .max, "Premium user should have unlimited goals")
    }
    
    // MARK: - Do It For Me Feature Tests
    
    func testCanUseDoItForMe_PremiumUser_Always() {
        // Given
        service.setPremium(true)
        
        // When
        let canUse = service.canUseDoItForMe()
        
        // Then
        XCTAssertTrue(canUse, "Premium user should always use DoItForMe")
    }
    
    // MARK: - Expand Step Feature Tests
    
    func testCanExpandStep_PremiumUser_Always() {
        // Given
        service.setPremium(true)
        
        // When
        let canUse = service.canExpandStep()
        
        // Then
        XCTAssertTrue(canUse, "Premium user should always expand steps")
    }
    
    // MARK: - Remaining Uses Tests
    
    func testGetRemainingUses_PremiumUser_Unlimited() {
        // Given
        service.setPremium(true)
        
        // When
        let doItForMeRemaining = service.getDoItForMeRemaining()
        let expandRemaining = service.getExpandRemaining()
        
        // Then
        XCTAssertEqual(doItForMeRemaining, .max, "Premium should have unlimited DoItForMe")
        XCTAssertEqual(expandRemaining, .max, "Premium should have unlimited Expand")
    }
    
    // MARK: - Premium State Tests
    
    func testSetPremium_UpdatesState() {
        // Given
        service.setPremium(false)
        XCTAssertFalse(service.isPremium)
        
        // When
        service.setPremium(true)
        
        // Then
        XCTAssertTrue(service.isPremium)
    }
    
    func testClearPremiumStatus_ResetsToPremiumFalse() {
        // Given
        service.setPremium(true)
        
        // When
        service.clearPremiumStatus()
        
        // Then
        XCTAssertFalse(service.isPremium)
    }
}

