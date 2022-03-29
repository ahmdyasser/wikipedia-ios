import XCTest
@testable import Wikipedia

class NotificationsCenterCellViewModelUserGroupRightsChangeTests: NotificationsCenterViewModelTests {

    override var dataFileName: String {
        get {
            return "notifications-userRights"
        }
    }
    
    func testUserRightsChange() throws {
        let notification = try fetchManagedObject(identifier: "1")
        guard let cellViewModel = NotificationsCenterCellViewModel(notification: notification, languageLinkController: languageLinkController, isEditing: false, configuration: configuration) else {
            throw TestError.failureConvertingManagedObjectToViewModel
        }
        
        try testUserRightsChangeText(cellViewModel: cellViewModel)
        try testUserRightsChangeIcons(cellViewModel: cellViewModel)
        try testUserRightsChangeActions(cellViewModel: cellViewModel)
    }
    
    private func testUserRightsChangeText(cellViewModel: NotificationsCenterCellViewModel) throws {
        XCTAssertEqual(cellViewModel.headerText, "User rights change", "Invalid headerText")
        XCTAssertEqual(cellViewModel.subheaderText, "From Jack The Cat", "Invalid subheaderText")
        XCTAssertEqual(cellViewModel.bodyText, "Your user rights were changed. You have been added to: Confirmed users.", "Invalid bodyText")
        XCTAssertEqual(cellViewModel.footerText, nil, "Invalid footerText")
        XCTAssertEqual(cellViewModel.dateText, "5/13/20", "Invalid dateText")
        XCTAssertEqual(cellViewModel.projectText, "EN", "Invalid projectText")
    }
    
    private func testUserRightsChangeIcons(cellViewModel: NotificationsCenterCellViewModel) throws {
        XCTAssertNil(cellViewModel.projectIconName, "Invalid projectIconName")
        XCTAssertEqual(cellViewModel.footerIconType, nil, "Invalid footerIconType")
    }
    
    private func testUserRightsChangeActions(cellViewModel: NotificationsCenterCellViewModel) throws {

        XCTAssertEqual(cellViewModel.sheetActions.count, 5, "Invalid sheetActionsCount")
        
        let expectedText0 = "Mark as unread"
        let expectedURL0: URL? = nil
        try testActions(expectedText: expectedText0, expectedURL: expectedURL0, actionToTest: cellViewModel.sheetActions[0], isMarkAsRead: true)
        
        let expectedText1 = "Go to Special:ListGroupRights#confirmed"
        let expectedURL1: URL? = URL(string: "https://en.wikipedia.org/wiki/Special:ListGroupRights?#confirmed")!
        try testActions(expectedText: expectedText1, expectedURL: expectedURL1, actionToTest: cellViewModel.sheetActions[1])
        
        let expectedText2 = "Go to Jack The Cat\'s user page"
        let expectedURL2: URL? = URL(string: "https://en.wikipedia.org/wiki/User:Jack_The_Cat")!
        try testActions(expectedText: expectedText2, expectedURL: expectedURL2, actionToTest: cellViewModel.sheetActions[2])
        
        let expectedText3 = "Go to Special:ListGroupRights"
        let expectedURL3: URL? = URL(string: "https://en.wikipedia.org/wiki/Special:ListGroupRights?")!
        try testActions(expectedText: expectedText3, expectedURL: expectedURL3, actionToTest: cellViewModel.sheetActions[3])
        
        let expectedText4 = "Notification settings"
        let expectedURL4: URL? = nil
        try testActions(expectedText: expectedText4, expectedURL: expectedURL4, actionToTest: cellViewModel.sheetActions[4], isNotificationSettings: true)
        
        
    }

}
