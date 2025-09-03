@testable import ImageFeed
import XCTest

final class ProfileViewTests: XCTestCase {
    func test_viewDidLoad_sendsProfileAndAvatar() {
        let viewSpy = ProfileViewSpy()
        let sampleProfile = Profile(username: "testuser", name: "Test User", loginName: "@testuser", bio: "Test Bio")
        let presenter = ProfilePresenter(
            profileService: StubProfileService(profile: sampleProfile),
            profileImageService: StubProfileImageService(),
            logoutService: StubProfileLogoutService()
        )
        presenter.view = viewSpy

        presenter.viewDidLoad()

        XCTAssertTrue(viewSpy.updateProfileCalled)
        XCTAssertTrue(viewSpy.updateAvatarCalled)
    }
    
    func test_viewDidLoad_callsPresenter() {
        let vc = ProfileViewController()
        let presenterSpy = ProfilePresenterSpy()
        vc.configure(presenterSpy)

        vc.loadViewIfNeeded()

        XCTAssertTrue(presenterSpy.viewDidLoadCalled)
    }

    func test_didTapButton_callsPresenter() {
        let vc = ProfileViewController()
        let presenterSpy = ProfilePresenterSpy()
        vc.configure(presenterSpy)
        
        vc.loadViewIfNeeded()
        
        vc.didTapButton()
        
        XCTAssertTrue(presenterSpy.didTapLogoutCalled)
    }
    func test_viewDidLoad_updatesView() {
       
        let sampleProfile = Profile(username: "alice", name: "Alice", loginName: "@alice", bio: "iOS Dev")
        let sampleURL     = "https://example.com/avatar.jpg"

        let profileStub   = StubProfileService(profile: sampleProfile)
        let imageStub     = StubProfileImageService(avatarURL: sampleURL)
        let logoutStub    = StubProfileLogoutService()

        let viewSpy = ProfileViewSpy()

        let presenter = ProfilePresenter(
            profileService: profileStub,
            profileImageService: imageStub,
            logoutService: logoutStub
        )
        presenter.view = viewSpy

        presenter.viewDidLoad()

        XCTAssertTrue(viewSpy.updateProfileCalled)
        XCTAssertTrue(viewSpy.updateAvatarCalled)
    }
}
