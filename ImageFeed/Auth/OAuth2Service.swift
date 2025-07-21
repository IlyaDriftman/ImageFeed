import Foundation

final class OAuth2Service {
    static let shared = OAuth2Service()
    
    private init() { }
    
    // MARK: - Public API
    
    func fetchOAuthToken(
        code: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let request = makeOAuthTokenRequest(code: code) else {
            completion(.failure(OAuth2Error.invalidRequest))
            return
        }
        
        URLSession.shared.objectTask(for: request) { (result: Result<(OAuthTokenResponseBody, HTTPURLResponse), Error>) in
            switch result {
            case .success((let body, let response)):
                if (200..<300).contains(response.statusCode) {
                    print("Status code: \(response.statusCode)")
                    print("Access token: \(body.accessToken)")
                    let token = body.accessToken
                    OAuth2TokenStorage.shared.token = token
                    completion(.success(token))
                } else {
                    print("Ошибка HTTP: \(response.statusCode)")
                    completion(.failure(OAuth2Error.invalidResponse))
                }
            case .failure(let error):
                print("Ошибка запроса токена: \(error)")
                completion(.failure(error))
            }
        }
    }
    
}
private extension OAuth2Service {
    private func makeOAuthTokenRequest(code: String) -> URLRequest? {
        guard let url = URL(string: "https://unsplash.com/oauth/token") else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let parameters: [String: String] = [
            "client_id": Constants.accessKey,
            "client_secret": Constants.secretKey,
            "redirect_uri": Constants.redirectURI,
            "code": code,
            "grant_type": "authorization_code"
        ]
        
        let bodyString = parameters
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
        
        request.httpBody = bodyString.data(using: .utf8)
        
        return request
    }

     
}

extension URLSession {
    func objectTask<T: Decodable>(
        for request: URLRequest,
        completion: @escaping (Result<(T, HTTPURLResponse), Error>) -> Void
    ) {
        let task = dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }

            guard
                let data = data,
                let response = response as? HTTPURLResponse
            else {
                DispatchQueue.main.async {
                    completion(.failure(OAuth2Error.invalidResponse))
                }
                return
            }

            do {
                if let rawString = String(data: data, encoding: .utf8) {
                    print("📦 Raw response:\n\(rawString)")
                }
                let decodedObject = try JSONDecoder().decode(T.self, from: data)
                DispatchQueue.main.async {
                    completion(.success((decodedObject, response)))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        task.resume()
    }
}
