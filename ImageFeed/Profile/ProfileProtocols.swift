import Foundation

// 1. Профиль
protocol ProfileServiceProtocol {
    var profile: Profile? { get }
}

// 2. Аватар
protocol ProfileImageServiceProtocol {
    var avatarURL: String? { get }
}

// 3. Логаут
protocol ProfileLogoutServiceProtocol {
    func logout()
}


