import Foundation

// MARK: - Модель изображения профиля
struct ProfileImage: Codable {
    let small: String
    let medium: String
    let large: String
}

// MARK: - Модель результата пользователя
struct UserResult: Codable {
    let username: String
    let profileImage: ProfileImage // ❗️Сделан обязательным — как в JSON
}

// MARK: - Сервис загрузки аватарки
final class ProfileImageService {
    static let didChangeNotification = Notification.Name("ProfileImageProviderDidChange")

    static let shared = ProfileImageService()
    private init() {}

    private(set) var avatarURL: String?
    private var task: URLSessionTask?

    func fetchProfileImageURL(username: String, completion: @escaping (Result<String, Error>) -> Void) {
        task?.cancel()

        print("[ProfileImageService.fetchProfileImageURL]: Запрос для username = \(username)")

        guard let token = OAuth2TokenStorage.shared.token else {
            let error = NSError(
                domain: "ProfileImageService",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "Authorization token missing"]
            )
            print("[ProfileImageService.fetchProfileImageURL]: AuthorizationError - \(error.localizedDescription), username: \(username)")
            completion(.failure(error))
            return
        }

        guard let request = makeProfileImageRequest(username: username, token: token) else {
            print("[ProfileImageService.makeProfileImageRequest]: URLError - Некорректный URL для username: \(username)")
            completion(.failure(URLError(.badURL)))
            return
        }

        let task = URLSession.shared.objectTask(for: request) { [weak self] (result: Result<UserResult, Error>) in
            guard let self = self else { return }

            switch result {
            case .success(let result):
                let url = result.profileImage.medium
                self.avatarURL = url
                print("[ProfileImageService.fetchProfileImageURL]: Успешно получили URL: \(url) для username: \(username)")
                completion(.success(url))

                NotificationCenter.default.post(
                    name: ProfileImageService.didChangeNotification,
                    object: self,
                    userInfo: ["URL": url]
                )

            case .failure(let error):
                print("[ProfileImageService.fetchProfileImageURL]: NetworkError - \(error.localizedDescription), username: \(username)")
                completion(.failure(error))
            }
        }

        self.task = task
        task.resume()
    }

    private func makeProfileImageRequest(username: String, token: String) -> URLRequest? {
        guard let encodedUsername = username.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "https://api.unsplash.com/users/\(encodedUsername)") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
}
