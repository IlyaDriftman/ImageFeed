import Foundation

final class OAuth2Service {
    static let shared = OAuth2Service()
    private init() { }
    private var currentTask: URLSessionTask?
    private var lastCode: String?
    
    // MARK: - Public API
    func fetchOAuthToken(
        code: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        if currentTask != nil, lastCode == code {
            print("[OAuth2Service.fetchOAuthToken]: RequestAlreadyInProgress - code: \(code)")
            completion(.failure(OAuth2Error.requestAlreadyInProgress))
            return
        }
        
        if currentTask != nil, lastCode != code {
            print("[OAuth2Service.fetchOAuthToken]: Cancelling previous request - new code: \(code)")
            currentTask?.cancel()
        }
        
        lastCode = code
        
        guard let request = makeOAuthTokenRequest(code: code) else {
            print("[OAuth2Service.makeOAuthTokenRequest]: InvalidRequest - could not create URLRequest")
            completion(.failure(OAuth2Error.invalidRequest))
            return
        }
        
        let task = URLSession.shared.objectTask(for: request) { [weak self] (result: Result<OAuthTokenResponseBody, Error>) in
            guard let self = self else { return }
            defer { self.currentTask = nil; self.lastCode = nil }
            
            switch result {
            case .success(let decoded):
                print("[OAuth2Service.fetchOAuthToken]: Token получен")
                OAuth2TokenStorage.shared.token = decoded.accessToken
                completion(.success(decoded.accessToken))
                
            case .failure(let error):
                if let urlError = error as? URLError, urlError.code == .cancelled {
                    print("[OAuth2Service.fetchOAuthToken]: Request cancelled manually, code: \(code)")
                    return
                }
                
                print("[OAuth2Service.fetchOAuthToken]: \(type(of: error)) - \(error.localizedDescription), code: \(code)")
                completion(.failure(error))
            }
        }
        
        currentTask = task
        task.resume()
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
