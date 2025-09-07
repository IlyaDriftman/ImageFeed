enum OAuth2Error: Error {
    case invalidRequest
    case invalidResponse
    case missingToken
    case requestAlreadyInProgress
    case serverError
    case networkError

    var localizedDescription: String {
        switch self {
        case .invalidRequest:
            return "Неверный запрос"
        case .invalidResponse:
            return "Неверный ответ сервера"
        case .missingToken:
            return "Токен не найден"
        case .requestAlreadyInProgress:
            return "Запрос уже выполняется"
        case .serverError:
            return "Ошибка сервера"
        case .networkError:
            return "Ошибка сети"
        }
    }
}
