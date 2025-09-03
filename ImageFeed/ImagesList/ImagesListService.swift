import Foundation
import UIKit

final class ImagesListService {
    // MARK: - Public API
    static let shared = ImagesListService()
    init() {}

    static let didChangeNotification = Notification.Name(
        "ImagesListServiceDidChange"
    )

    private(set) var photos: [Photo] = []

    // MARK: - Private properties
    private var task: URLSessionTask?
    private var lastLoadedPage: Int?
    private let perPage = 10

    // MARK: - Like / Unlike
    func changeLike(
        photoId: String,
        isLike: Bool,
        _ completion: @escaping (Result<Void, Error>) -> Void
    ) {
        print(
            " [ImagesListService] Отправляем запрос на изменение лайка: \(photoId) -> \(isLike)"
        )

        guard
            let request = makeChangeLikeRequest(
                photoId: photoId,
                isLike: isLike
            )
        else {
            print("[ImagesListService] Не удалось создать запрос")
            completion(.failure(NetworkError.invalidRequest))
            return
        }

        print(" [ImagesListService] Запрос создан, отправляем...")

        let task = URLSession.shared.data(for: request) { [weak self] result in
            guard let self = self else { return }
            print(" [ImagesListService] Получен ответ от сервера")

            switch result {
            case .success:
                print("[ImagesListService] Запрос успешен")
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }

                    if let index = self.photos.firstIndex(where: { $0.id == photoId }) {
                        print("[ImagesListService] Найден индекс: \(index)")
                        var updatedPhotos = self.photos
                        updatedPhotos[index].isLiked = isLike
                        self.photos = updatedPhotos

                        print("[ImagesListService] Модель обновлена, отправляем нотификацию")
                        NotificationCenter.default.post(
                            name: ImagesListService.didChangeNotification,
                            object: self,
                            userInfo: ["photos": self.photos]
                        )
                    }
                    completion(.success(()))
                }

            case .failure(let error):
                print("[ImagesListService] Ошибка: \(error)")

                // Обработка HTTP ошибок
                if case NetworkError.httpStatusCode(let statusCode) = error {
                    let errorMessage = self.mapHTTPStatusCodeToLikeError(statusCode)
                    print("[ImagesListService] HTTP ошибка \(statusCode) -> \(errorMessage)")
                    DispatchQueue.main.async { [weak self] in
                        guard self != nil else { return }
                        completion(.failure(NetworkError.httpStatusCode(statusCode)))
                    }
                } else {
                    print("[ImagesListService] Сетевая ошибка: \(error.localizedDescription)")
                    DispatchQueue.main.async { [weak self] in
                        guard self != nil else { return }
                        completion(.failure(error))
                    }
                }
            }
        }

        print("[ImagesListService] Задача запущена")
        task.resume()
    }

    // MARK: - Private Helpers
    private func makeChangeLikeRequest(photoId: String, isLike: Bool)
        -> URLRequest?
    {
        let urlString = "https://api.unsplash.com/photos/\(photoId)/like"
        print("[ImagesListService] Создаем запрос на URL: \(urlString)")

        guard let url = URL(string: urlString) else {
            print("[ImagesListService] Неверный URL")
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = isLike ? "POST" : "DELETE"

        print("[ImagesListService] HTTP метод: \(request.httpMethod ?? "nil")")

        guard let token = OAuth2TokenStorage.shared.token else {
            print("[ImagesListService] Токен отсутствует")
            return nil
        }

        print(" [ImagesListService] Токен найден: \(token.prefix(20))...")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30
        print("[ImagesListService] Запрос сформирован успешно")
        return request
    }

    // MARK: - Public Methods
    func fetchPhotosNextPage() {
        if task != nil {
            print("[ImagesListService] Загрузка уже идет, пропускаем")
            return
        }
        let nextPage = (lastLoadedPage ?? 0) + 1
        print(" [ImagesListService] Загружаем страницу \(nextPage)")

        guard let request = makePhotosRequest(page: nextPage) else {
            print(
                "[ImagesListService]: InvalidRequest - cannot create request for page \(nextPage)"
            )
            return
        }

        let task = URLSession.shared.objectTask(for: request) {
            [weak self] (result: Result<[PhotoResult], Error>) in
            guard let self else { return }
            switch result {
            case .success(let photoResults):
                print(
                    "[ImagesListService] Получено \(photoResults.count) фото для страницы \(nextPage)"
                )
                self.handleSuccess(photoResults, nextPage: nextPage)
            case .failure(let error):
                print(
                    "[ImagesListService]: \(type(of: error)) - \(error.localizedDescription)"
                )
            }
            self.task = nil
        }

        self.task = task
        task.resume()
    }

    private func handleSuccess(_ photoResults: [PhotoResult], nextPage: Int) {
        let incoming = photoResults.map(convert)
        let unique = incoming.filter { newPhoto in
            !self.photos.contains(where: { $0.id == newPhoto.id })
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.photos.append(contentsOf: unique)
            self.lastLoadedPage = nextPage
            NotificationCenter.default.post(
                name: ImagesListService.didChangeNotification,
                object: self,
                userInfo: ["photos": self.photos]
            )
        }
    }
    
    private func convert(from result: PhotoResult) -> Photo {
        let size = CGSize(width: result.width, height: result.height)
        let createdAtDate: Date? = {
            guard let createdAt = result.createdAt else { return nil }
            let formatter = ISO8601DateFormatter()
            return formatter.date(from: createdAt)
        }()

        return Photo(
            id: result.id,
            size: size,
            createdAt: createdAtDate,
            thumbImageURL: result.urls.small,
            largeImageURL: result.urls.full,
            isLiked: result.likedByUser ?? false
        )
    }

    private func makePhotosRequest(page: Int) -> URLRequest? {
        guard
            var urlComponents = URLComponents(
                url: Constants.defaultBaseURL,
                resolvingAgainstBaseURL: false
            )
        else {
            return nil
        }
        urlComponents.path = "/photos"
        urlComponents.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "order_by", value: "latest"),
            URLQueryItem(name: "per_page", value: String(perPage)),
        ]

        guard let url = urlComponents.url else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        if let token = OAuth2TokenStorage.shared.token {
            request.setValue(
                "Bearer \(token)",
                forHTTPHeaderField: "Authorization"
            )
        } else {
            request.setValue(
                "Client-ID \(Constants.accessKey)",
                forHTTPHeaderField: "Authorization"
            )
        }

        return request
    }

    func clearPhotos() {
        photos.removeAll()
        lastLoadedPage = nil
        print("[ImagesListService] Список изображений очищен")
    }
    
    // MARK: - Private Helpers
    private func mapHTTPStatusCodeToLikeError(_ statusCode: Int) -> String {
        switch statusCode {
        case 400:
            return "Неверный запрос"
        case 401:
            return "Необходима авторизация"
        case 403:
            return "Доступ запрещен"
        case 404:
            return "Фотография не найдена"
        case 500...599:
            return "Ошибка сервера"
        default:
            return "Ошибка сети"
        }
    }
}
