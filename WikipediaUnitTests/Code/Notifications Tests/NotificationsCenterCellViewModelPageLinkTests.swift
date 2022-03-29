import XCTest
@testable import Wikipedia

class NotificationsCenterCellViewModelPageLinkTests: NotificationsCenterViewModelTests {
    
    override var dataFileName: String {
        get {
            return "notifications-pageLink"
        }
    }

    func testPageLink() throws {
        let notification = try fetchManagedObject(identifier: "1")
        guard let cellViewModel = NotificationsCenterCellViewModel(notification: notification, languageLinkController: languageLinkController, isEditing: false, configuration: configuration) else {
            throw TestError.failureConvertingManagedObjectToViewModel
        }
        
        try testPageLinkText(cellViewModel: cellViewModel)
        try testPageLinkIcons(cellViewModel: cellViewModel)
        try testPageLinkActions(cellViewModel: cellViewModel)
    }
    
    private func testPageLinkText(cellViewModel: NotificationsCenterCellViewModel) throws {
        XCTAssertEqual(cellViewModel.headerText, "Page link", "Invalid headerText")
        XCTAssertEqual(cellViewModel.subheaderText, "From Jack The Cat", "Invalid subheaderText")
        XCTAssertEqual(cellViewModel.bodyText, "A link was made from Black Cat to Blue Bird.", "Invalid bodyText")
        XCTAssertEqual(cellViewModel.footerText, "Blue Bird", "Invalid footerText")
        XCTAssertEqual(cellViewModel.dateText, "1/25/20", "Invalid dateText")
        XCTAssertEqual(cellViewModel.projectText, "EN", "Invalid projectText")
    }
    
    private func testPageLinkIcons(cellViewModel: NotificationsCenterCellViewModel) throws {
        XCTAssertNil(cellViewModel.projectIconName, "Invalid projectIconName")
        XCTAssertEqual(cellViewModel.footerIconType, .documentFill, "Invalid footerIconType")
    }
    
    private func testPageLinkActions(cellViewModel: NotificationsCenterCellViewModel) throws {

        XCTAssertEqual(cellViewModel.sheetActions.count, 6, "Invalid sheetActionsCount")
        
        let expectedText0 = "Mark as unread"
        let expectedURL0: URL? = nil
        try testActions(expectedText: expectedText0, expectedURL: expectedURL0, actionToTest: cellViewModel.sheetActions[0], isMarkAsRead: true)
        
        let expectedText1 = "Go to Jack The Cat\'s user page"
        let expectedURL1: URL? = URL(string: "https://en.wikipedia.org/wiki/User:Jack_The_Cat")!
        try testActions(expectedText: expectedText1, expectedURL: expectedURL1, actionToTest: cellViewModel.sheetActions[1])
        
        let expectedText2 = "Go to Black Cat"
        let expectedURL2: URL? = URL(string: "https://en.wikipedia.org/wiki/Black_Cat?")!
        try testActions(expectedText: expectedText2, expectedURL: expectedURL2, actionToTest: cellViewModel.sheetActions[2])
        
        let expectedText3 = "Go to Blue Bird"
        let expectedURL3: URL? = URL(string: "https://en.wikipedia.org/wiki/Blue_Bird")!
        try testActions(expectedText: expectedText3, expectedURL: expectedURL3, actionToTest: cellViewModel.sheetActions[3])
        
        let expectedText4 = "Go to diff"
        let expectedURL4: URL? = URL(string: "https://en.wikipedia.org/w/index.php?oldid=937467985&title=Blue_Bird")!
        try testActions(expectedText: expectedText4, expectedURL: expectedURL4, actionToTest: cellViewModel.sheetActions[4])
        
        let expectedText5 = "Notification settings"
        let expectedURL5: URL? = nil
        try testActions(expectedText: expectedText5, expectedURL: expectedURL5, actionToTest: cellViewModel.sheetActions[5], isNotificationSettings: true)
    }
}
