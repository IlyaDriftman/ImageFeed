import UIKit

protocol AuthViewControllerDelegate: AnyObject {
    func didAuthenticate(_ vc: AuthViewController)
}

final class AuthViewController: UIViewController {
    private let showWebViewSegueIdentifier = "ShowWebView"
    private let oauth2Service = OAuth2Service.shared

    weak var delegate: AuthViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        configureBackButton()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showWebViewSegueIdentifier {
            guard
                let webViewViewController = segue.destination
                    as? WebViewViewController
            else {
                assertionFailure(
                    "Failed to prepare for \(showWebViewSegueIdentifier)"
                )
                return
            }
            let authHelper = AuthHelper()
            let webViewPresenter = WebViewPresenter(authHelper: authHelper)
            webViewViewController.presenter = webViewPresenter
            webViewPresenter.view = webViewViewController
            webViewViewController.delegate = self
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }

    private func configureBackButton() {
        navigationController?.navigationBar.backIndicatorImage = UIImage(
            resource: .navBackButtonWhite
        )
        navigationController?.navigationBar.backIndicatorTransitionMaskImage =
            UIImage(resource: .navBackButtonWhite)
        navigationItem.backBarButtonItem = UIBarButtonItem(
            title: "",
            style: .plain,
            target: nil,
            action: nil
        )
        navigationItem.backBarButtonItem?.tintColor = UIColor(named: "ypBlack")
    }
}

extension AuthViewController: WebViewViewControllerDelegate {
    func webViewViewController(
        _ vc: WebViewViewController,
        didAuthenticateWithCode code: String
    ) {
        vc.dismiss(animated: true)
        UIBlockingProgressHUD.show()

        fetchOAuthToken(code) { [weak self] result in
            UIBlockingProgressHUD.dismiss()

            guard let self else { return }

            switch result {
            case .success:
                self.delegate?.didAuthenticate(self)
            case let .failure(error):
                print(
                    "Ошибка при аутентификации: \(error.localizedDescription)"
                )
                self.showAuthErrorAlert(error: error)
            }
        }
    }

    func webViewViewControllerDidCancel(_ vc: WebViewViewController) {
        vc.dismiss(animated: true)
    }
}

extension AuthViewController {
    private func fetchOAuthToken(
        _ code: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        oauth2Service.fetchOAuthToken(code: code) { result in
            completion(result)
        }
    }
}

extension AuthViewController {
    func showAuthErrorAlert(error: Error) {
        let title: String
        let message: String
        
        if let oauthError = error as? OAuth2Error {
            title = "Ошибка авторизации"
            message = oauthError.localizedDescription
        } else {
            title = "Что-то пошло не так("
            message = "Не удалось войти в систему. Попробуйте еще раз."
        }
        
        let alertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        
        let okAction = UIAlertAction(title: "ОК", style: .default) { _ in
            // После нажатия ОК пользователь может попробовать войти снова
        }
        alertController.addAction(okAction)
        
        present(alertController, animated: true, completion: nil)
    }
}
