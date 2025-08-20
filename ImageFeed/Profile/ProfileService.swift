import Foundation

final class ProfileService {
    static let shared = ProfileService()
    private init() {}
    
    private var task: URLSessionTask?
    private let urlSession = URLSession.shared
    
    private(set) var profile: Profile?

    func fetchProfile(_ token: String, completion: @escaping (Result<Profile, Error>) -> Void) {
        task?.cancel()
        
        guard let request = makeProfileRequest(token: token) else {
            print("[ProfileService.fetchProfile]: InvalidRequest - failed to create request, token: \(token)")
            completion(.failure(URLError(.badURL)))
            return
        }

        let task = URLSession.shared.objectTask(for: request) { [weak self] (result: Result<ProfileResult, Error>) in
            print("[ProfileService.fetchProfile]: Response received")
            switch result {
            case .success(let result):
                let name = [result.firstName, result.lastName]
                    .compactMap { $0 } // убираем nil
                    .joined(separator: " ")
                
                let profile = Profile(
                    username: result.username,
                    name: name,
                    loginName: "@\(result.username)",
                    bio: result.bio
                )
               
                self?.profile = profile
                completion(.success(profile))
               
            case .failure(let error):
                print("[ProfileService.fetchProfile]: \(type(of: error)) - \(error.localizedDescription), token: \(token)")
                completion(.failure(error))
            }
            self?.task = nil
        }

        self.task = task
        task.resume()
    }

    private func makeProfileRequest(token: String) -> URLRequest? {
        guard let url = URL(string: "https://api.unsplash.com/me") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
    
    func clearProfile() {
            profile = nil
            print("[ProfileService] Профиль очищен")
        }
}

