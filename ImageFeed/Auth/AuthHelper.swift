import Foundation

protocol AuthHelperProtocol {
    func authRequest() -> URLRequest?
    func code(from url: URL) -> String?
}

final class AuthHelper: AuthHelperProtocol {
    let configuration: AuthConfiguration

    init(configuration: AuthConfiguration = .standard) {
        self.configuration = configuration
    }

    func authRequest() -> URLRequest? {
        guard let url = authURL() else { return nil }

        return URLRequest(url: url)
    }

    func authURL() -> URL? {
        guard
            var urlComponents = URLComponents(
                string: configuration.authURLString
            )
        else {
            return nil
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: configuration.accessKey),
            URLQueryItem(
                name: "redirect_uri",
                value: configuration.redirectURI
            ),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: configuration.accessScope),
        ]

        return urlComponents.url
    }

    func code(from url: URL) -> String? {
        print("[AuthHelper]: Обрабатываем URL: \(url.absoluteString)")
        
        if let urlComponents = URLComponents(string: url.absoluteString),
            urlComponents.path == "/oauth/authorize/native",
            let items = urlComponents.queryItems
        {
            // Проверяем наличие кода авторизации
            if let codeItem = items.first(where: { $0.name == "code" }) {
                print("[AuthHelper]: Найден код авторизации: \(codeItem.value ?? "nil")")
                return codeItem.value
            }
            
            // Проверяем наличие ошибки
            if let errorItem = items.first(where: { $0.name == "error" }) {
                print("[AuthHelper]: Найдена ошибка в URL: \(errorItem.value ?? "nil")")
                // Возвращаем специальный код ошибки, который будет обработан в AuthViewController
                return "ERROR:\(errorItem.value ?? "unknown")"
            }
        }
        
        print("[AuthHelper]: URL не содержит код или ошибку")
        return nil
    }
}
