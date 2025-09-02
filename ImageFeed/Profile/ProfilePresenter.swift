import ObjectiveC
import UIKit
import Foundation

protocol ProfilePresenterProtocol: AnyObject {
    var view: ProfileViewProtocol? { get set }

    func viewDidLoad()            // вызовем в VC.viewDidLoad()
    func didTapLogoutButton()     // вызовем в didTapButton()
    func performLogoutConfirmed() // вызовем, когда юзер нажмёт «Да» в алерте
}

final class ProfilePresenter: ProfilePresenterProtocol {
    weak var view: ProfileViewProtocol?
    private let profileService: ProfileServiceProtocol
    private let profileImageService: ProfileImageServiceProtocol
    private let logoutService: ProfileLogoutServiceProtocol
    private var avatarObserver: NSObjectProtocol?

    init(profileService: ProfileServiceProtocol = ProfileService.shared,
             profileImageService: ProfileImageServiceProtocol = ProfileImageService.shared,
             logoutService: ProfileLogoutServiceProtocol = ProfileLogoutService.shared) {
            self.profileService      = profileService
            self.profileImageService = profileImageService
            self.logoutService       = logoutService
        }

    // MARK: VC ➜ Presenter
    func viewDidLoad() {
        // Профиль
        if let profile = profileService.profile {
            view?.updateProfileDetails(profile: profile)
        }
        // Аватар
        view?.updateAvatar()

        // Подписка на изменения аватара
        avatarObserver = NotificationCenter.default.addObserver(
            forName: ProfileImageService.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.view?.updateAvatar()
        }
    }

    func didTapLogoutButton() {
        view?.showLogoutAlert()
    }

    func performLogoutConfirmed() {
        logoutService.logout()

        guard let window = UIApplication.shared.windows.first else {
            assertionFailure("Окно не найдено")
            return
        }
        let splashVC = SplashViewController()
        window.rootViewController = splashVC
        UIView.transition(with: window,
                          duration: 0.3,
                          options: .transitionCrossDissolve,
                          animations: {},
                          completion: nil)
    }
}
