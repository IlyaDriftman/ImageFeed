import UIKit

class ProfileViewController: UIViewController {
    private var label: UILabel!
    private var loginName: UILabel!
    private var descr: UILabel!
    private var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fProfileImage()
        fLabel()
        fLoginName()
        fDesc()
        fLogoutBut()
    }
    
    func fProfileImage() {
        let profileImage = UIImage(named: "avatar")
        imageView = UIImageView(image: profileImage)
        imageView.tintColor = .gray
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        imageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16).isActive = true
        imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: 70).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 70).isActive = true
    }
    
    func fLabel() {
        label = UILabel()
        label.text = "Екатерина Новикова"
        label.font = UIFont.systemFont(ofSize: 23, weight: .bold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        label.leadingAnchor.constraint(equalTo: imageView.leadingAnchor).isActive = true
        label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8).isActive = true
        }
    
    func fLoginName() {
        loginName = UILabel()
        loginName.text = "@ekaterina_nov"
        loginName.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        loginName.textColor = .gray
        loginName.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loginName)
        loginName.leadingAnchor.constraint(equalTo: label.leadingAnchor).isActive = true
        loginName.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 8).isActive = true
    }
    
    func fDesc() {
        descr = UILabel()
        descr.text = "Hello, world!"
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
        button.tintColor = UIColor(hex: "#F56B6C")
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)
        button.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20).isActive = true
        button.centerYAnchor.constraint(equalTo: imageView.centerYAnchor).isActive = true
    }
        @objc
        private func didTapButton() {
        
            for view in view.subviews {
                if view is UILabel {
                    view.removeFromSuperview()
                }
            }
        }
}
extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}
