import UIKit
import Kingfisher

final class ProfileViewController: UIViewController {
    private var label: UILabel!
    private var loginName: UILabel!
    private var descr: UILabel!
    private var imageView: UIImageView!
    private var profileImageServiceObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .ypBlack
        
        fProfileImage()
        fLabel()
        fLoginName()
        fDesc()
        fLogoutBut()
        
        if let profile = ProfileService.shared.profile {
            updateProfileDetails(profile: profile)
        }
        profileImageServiceObserver = NotificationCenter.default
            .addObserver(
                forName: ProfileImageService.didChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self = self else { return }
                self.updateAvatar()
            }
        updateAvatar()
    }
    
    private func updateAvatar() {
        guard
            let profileImageURL = ProfileImageService.shared.avatarURL,
            let imageUrl = URL(string: profileImageURL)
        else { return }
        
        print("imageUrl: \(imageUrl)")
        
        let placeholderImage = UIImage(systemName: "person.circle.fill")?
            .withTintColor(.lightGray, renderingMode: .alwaysOriginal)
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 70, weight: .regular, scale: .large))
        
        let processor = RoundCornerImageProcessor(cornerRadius: 20) 
        imageView.kf.indicatorType = .activity
        imageView.kf.setImage(
            with: imageUrl,
            placeholder: placeholderImage,
            options: [
                .processor(processor),
                .scaleFactor(UIScreen.main.scale),
                .cacheOriginalImage,
                .forceRefresh
            ]) { result in
                
                switch result {
                case .success(_):
                    print("загружно")
                case .failure(let error):
                    print(error)
                }
            }
    }
    
    private func updateProfileDetails(profile: Profile) {
        label.text = profile.name
        loginName.text = profile.loginName
        descr.text = profile.bio
    }
    
    func fProfileImage() {
        let profileImage = UIImage(named: "avatar")
        imageView = UIImageView(image: profileImage)
        imageView.tintColor = .gray
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        imageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16).isActive = true
        imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: 70).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 70).isActive = true
    }
    
    func fLabel() {
        label = UILabel()
        label.text = "" // Изначально пусто, до вызова updateProfileDetails
        label.font = UIFont.systemFont(ofSize: 23, weight: .bold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        label.leadingAnchor.constraint(equalTo: imageView.leadingAnchor).isActive = true
        label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8).isActive = true
    }
    
    func fLoginName() {
        loginName = UILabel()
        loginName.text = ""
        loginName.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        loginName.textColor = .gray
        loginName.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loginName)
        loginName.leadingAnchor.constraint(equalTo: label.leadingAnchor).isActive = true
        loginName.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 8).isActive = true
    }
    
    func fDesc() {
        descr = UILabel()
        descr.text = ""
        descr.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        descr.textColor = .white
        descr.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(descr)
        descr.leadingAnchor.constraint(equalTo: loginName.leadingAnchor).isActive = true
        descr.topAnchor.constraint(equalTo: loginName.bottomAnchor, constant: 8).isActive = true
    }
    
    func fLogoutBut() {
        let button = UIButton.systemButton(
            with: UIImage(named: "logout_button")!,
            target: self,
            action: #selector(Self.didTapButton)
        )
        button.tintColor = UIColor(named: "YP Red")
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)
        button.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20).isActive = true
        button.centerYAnchor.constraint(equalTo: imageView.centerYAnchor).isActive = true
    }
    
    @objc
    private func didTapButton() {
        let alert = UIAlertController(
            title: "Пока, пока!",
            message: "Уверены, что хотите выйти?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Да", style: .default) { _ in
            ProfileLogoutService.shared.logout()
            
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
        })
        alert.addAction(UIAlertAction(title: "Нет", style: .default))
        present(alert, animated: true)
    }
    
}
