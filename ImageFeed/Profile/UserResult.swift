import Foundation

// MARK: - Модель результата пользователя
struct UserResult: Codable {
    let username: String
    let profileImage: ProfileImage // ❗️Сделан обязательным — как в JSON
}
