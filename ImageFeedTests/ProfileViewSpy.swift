@testable import ImageFeed
import Foundation

final class ProfileViewSpy: ProfileViewProtocol {
    var updateProfileCalled = false
    var updateAvatarCalled  = false
    var showLogoutAlertCalled = false

    func updateProfileDetails(profile: Profile) { updateProfileCalled = true }
    func updateAvatar()                           { updateAvatarCalled = true }
    func showLogoutAlert()                        { showLogoutAlertCalled = true }
}

final class ProfilePresenterSpy: ProfilePresenterProtocol {
    weak var view: ProfileViewProtocol?
    var viewDidLoadCalled = false
    var didTapLogoutCalled = false

    func viewDidLoad()          { viewDidLoadCalled = true }
    func didTapLogoutButton()   { didTapLogoutCalled = true }
    func performLogoutConfirmed(){}
}
