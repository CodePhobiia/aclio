import XCTest
@testable import Aclio

/// Unit tests for Goal model
final class GoalTests: XCTestCase {
    
    // MARK: - Test Fixtures
    
    func makeGoal(
        steps: [Step] = [],
        completedSteps: [Int] = []
    ) -> Goal {
        Goal(
            id: 1,
            name: "Test Goal",
            category: "Test",
            iconKey: "target",
            iconColor: IconColor.options[0],
            dueDate: nil,
            steps: steps,
            completedSteps: completedSteps
        )
    }
    
    func makeStep(id: Int, title: String = "Step") -> Step {
        Step(id: id, title: title, description: "Description")
    }
    
    // MARK: - Progress Tests
    
    func testProgress_NoSteps_ReturnsZero() {
        let goal = makeGoal(steps: [])
        XCTAssertEqual(goal.progress, 0)
    }
    
    func testProgress_NoCompletedSteps_ReturnsZero() {
        let goal = makeGoal(
            steps: [makeStep(id: 1), makeStep(id: 2)],
            completedSteps: []
        )
        XCTAssertEqual(goal.progress, 0)
    }
    
    func testProgress_AllStepsCompleted_ReturnsHundred() {
        let goal = makeGoal(
            steps: [makeStep(id: 1), makeStep(id: 2)],
            completedSteps: [1, 2]
        )
        XCTAssertEqual(goal.progress, 100)
    }
    
    func testProgress_HalfCompleted_ReturnsFifty() {
        let goal = makeGoal(
            steps: [makeStep(id: 1), makeStep(id: 2)],
            completedSteps: [1]
        )
        XCTAssertEqual(goal.progress, 50)
    }
    
    func testProgress_OneOfThree_ReturnsThirtyThree() {
        let goal = makeGoal(
            steps: [makeStep(id: 1), makeStep(id: 2), makeStep(id: 3)],
            completedSteps: [1]
        )
        XCTAssertEqual(goal.progress, 33)
    }
    
    // MARK: - Completion Tests
    
    func testIsCompleted_NoSteps_ReturnsFalse() {
        let goal = makeGoal(steps: [])
        XCTAssertFalse(goal.isCompleted)
    }
    
    func testIsCompleted_AllCompleted_ReturnsTrue() {
        let goal = makeGoal(
            steps: [makeStep(id: 1)],
            completedSteps: [1]
        )
        XCTAssertTrue(goal.isCompleted)
    }
    
    func testIsCompleted_PartiallyCompleted_ReturnsFalse() {
        let goal = makeGoal(
            steps: [makeStep(id: 1), makeStep(id: 2)],
            completedSteps: [1]
        )
        XCTAssertFalse(goal.isCompleted)
    }
    
    // MARK: - Next Step Tests
    
    func testNextStep_NoSteps_ReturnsNil() {
        let goal = makeGoal(steps: [])
        XCTAssertNil(goal.nextStep)
    }
    
    func testNextStep_AllCompleted_ReturnsNil() {
        let goal = makeGoal(
            steps: [makeStep(id: 1)],
            completedSteps: [1]
        )
        XCTAssertNil(goal.nextStep)
    }
    
    func testNextStep_NoneCompleted_ReturnsFirstStep() {
        let steps = [makeStep(id: 1, title: "First"), makeStep(id: 2, title: "Second")]
        let goal = makeGoal(steps: steps, completedSteps: [])
        
        XCTAssertEqual(goal.nextStep?.id, 1)
        XCTAssertEqual(goal.nextStep?.title, "First")
    }
    
    func testNextStep_FirstCompleted_ReturnsSecondStep() {
        let steps = [makeStep(id: 1, title: "First"), makeStep(id: 2, title: "Second")]
        let goal = makeGoal(steps: steps, completedSteps: [1])
        
        XCTAssertEqual(goal.nextStep?.id, 2)
        XCTAssertEqual(goal.nextStep?.title, "Second")
    }
    
    // MARK: - Toggle Step Tests
    
    func testToggleStep_CompleteStep() {
        var goal = makeGoal(
            steps: [makeStep(id: 1)],
            completedSteps: []
        )
        
        XCTAssertFalse(goal.isStepCompleted(1))
        
        goal.toggleStep(1)
        
        XCTAssertTrue(goal.isStepCompleted(1))
    }
    
    func testToggleStep_UncompleteStep() {
        var goal = makeGoal(
            steps: [makeStep(id: 1)],
            completedSteps: [1]
        )
        
        XCTAssertTrue(goal.isStepCompleted(1))
        
        goal.toggleStep(1)
        
        XCTAssertFalse(goal.isStepCompleted(1))
    }
    
    func testToggleStep_DoubleToogle_RestoresOriginalState() {
        var goal = makeGoal(
            steps: [makeStep(id: 1)],
            completedSteps: []
        )
        
        goal.toggleStep(1)
        goal.toggleStep(1)
        
        XCTAssertFalse(goal.isStepCompleted(1))
    }
    
    // MARK: - Counts Tests
    
    func testCompletedStepsCount() {
        let goal = makeGoal(
            steps: [makeStep(id: 1), makeStep(id: 2), makeStep(id: 3)],
            completedSteps: [1, 2]
        )
        
        XCTAssertEqual(goal.completedStepsCount, 2)
    }
    
    func testTotalStepsCount() {
        let goal = makeGoal(
            steps: [makeStep(id: 1), makeStep(id: 2), makeStep(id: 3)],
            completedSteps: [1]
        )
        
        XCTAssertEqual(goal.totalStepsCount, 3)
    }
    
    // MARK: - Due Date Status Tests
    
    func testDueDateStatus_NoDueDate_ReturnsNil() {
        let goal = makeGoal()
        XCTAssertNil(goal.dueDateStatus)
    }
    
    func testDueDateStatus_Today_ReturnsTodayStatus() {
        var goal = makeGoal()
        goal.dueDate = Calendar.current.startOfDay(for: Date())
        
        XCTAssertEqual(goal.dueDateStatus, .today)
    }
    
    func testDueDateStatus_Past_ReturnsOverdue() {
        var goal = makeGoal()
        goal.dueDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        
        XCTAssertEqual(goal.dueDateStatus, .overdue)
    }
    
    func testDueDateStatus_Tomorrow_ReturnsSoon() {
        var goal = makeGoal()
        goal.dueDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        
        if case .soon(let days) = goal.dueDateStatus {
            XCTAssertEqual(days, 1)
        } else {
            XCTFail("Expected .soon status")
        }
    }
    
    func testDueDateStatus_FarFuture_ReturnsNormal() {
        var goal = makeGoal()
        goal.dueDate = Calendar.current.date(byAdding: .day, value: 10, to: Date())
        
        if case .normal(let days) = goal.dueDateStatus {
            XCTAssertEqual(days, 10)
        } else {
            XCTFail("Expected .normal status")
        }
    }
    
    // MARK: - Equatable Tests
    
    func testEquatable_SameGoals_AreEqual() {
        let goal1 = Goal(id: 1, name: "Test", category: "Cat", iconKey: "target", iconColor: IconColor.options[0])
        let goal2 = Goal(id: 1, name: "Test", category: "Cat", iconKey: "target", iconColor: IconColor.options[0])
        
        XCTAssertEqual(goal1, goal2)
    }
    
    func testEquatable_DifferentIds_AreNotEqual() {
        let goal1 = Goal(id: 1, name: "Test", category: "Cat", iconKey: "target", iconColor: IconColor.options[0])
        let goal2 = Goal(id: 2, name: "Test", category: "Cat", iconKey: "target", iconColor: IconColor.options[0])
        
        XCTAssertNotEqual(goal1, goal2)
    }
}

