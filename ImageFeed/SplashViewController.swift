import UIKit

final class SplashViewController: UIViewController {
    private let profileService = ProfileService.shared
    private let storage = OAuth2TokenStorage.shared
    private let showAuthenticationScreenSegueIdentifier = "ShowAuthenticationScreen"
    
    private let logoImageView: UIImageView = {
            let imageView = UIImageView()
            imageView.image = UIImage(named: "splash_screen_logo")
            imageView.translatesAutoresizingMaskIntoConstraints = false
            return imageView
        }()
    
    override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .black // Или любой другой фон
            layoutLogo()
        }

        private func layoutLogo() {
            view.addSubview(logoImageView)

            NSLayoutConstraint.activate([
                logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
        }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let token = storage.token {
            print("Токен найден, загружаем профиль")
          //  switchToTabBarController()
            fetchProfile(token: token)
        } else {
            print("Токен не найден, показываем экран авторизации")
            showAuthScreen()
        }
    }
    
    private func showAuthScreen() {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        guard let authViewController = storyboard.instantiateViewController(withIdentifier: "AuthViewController") as? AuthViewController else {
            assertionFailure("Не удалось найти AuthViewController по идентификатору")
            return
        }
        authViewController.delegate = self
        authViewController.modalPresentationStyle = .fullScreen
        present(authViewController, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    private func switchToTabBarController() {
        print("Переключаемся на TabBar")
        guard let window = UIApplication.shared.windows.first else {
            assertionFailure("Invalid window configuration")
            return
        }

        let tabBarController = UIStoryboard(name: "Main", bundle: .main)
            .instantiateViewController(withIdentifier: "TabBarViewController")

        // Сбросим всю иерархию viewController'ов
        window.rootViewController = tabBarController
        window.makeKeyAndVisible()
    }

    private func fetchProfile(token: String) {
        print("Запуск fetchProfile")
        UIBlockingProgressHUD.show()

        profileService.fetchProfile(token) { [weak self] result in
            UIBlockingProgressHUD.dismiss()
            print("Result пришёл: \(result)")

            guard let self = self else { return }

            switch result {
            case let .success(profile):
                print("Профиль получен: \(profile.username)")
                ProfileImageService.shared.fetchProfileImageURL(username: profile.username) { imageResult in
                    print("Аватар обновлён: \(imageResult)")
                }
                self.switchToTabBarController()

            case let .failure(error):
                print("Ошибка при получении профиля: \(error)")
            }
        }
    }
}

extension SplashViewController: AuthViewControllerDelegate {
    func didAuthenticate(_ vc: AuthViewController) {
        print("✅ Авторизация успешна")
        guard let token = storage.token else {
            print("❌ Токен не получен")
            return
        }

        UIBlockingProgressHUD.show()
        
        profileService.fetchProfile(token) { [weak self] result in
            DispatchQueue.main.async {
                UIBlockingProgressHUD.dismiss()
                vc.dismiss(animated: false) // Сначала закрываем Auth
            }

            switch result {
            case let .success(profile):
                ProfileImageService.shared.fetchProfileImageURL(username: profile.username) { _ in }
                DispatchQueue.main.async {
                    self?.switchToTabBarController() // Плавно переключаемся
                }

            case let .failure(error):
                print("❌ Ошибка профиля: \(error)")
                // Можно показать UIAlert
            }
        }
    }

}
