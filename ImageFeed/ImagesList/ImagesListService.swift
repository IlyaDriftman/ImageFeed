import Foundation
import UIKit

final class ImagesListService {
    static let shared = ImagesListService()
    static let didChangeNotification = Notification.Name("ImagesListServiceDidChange")
    private(set) var photos: [Photo] = []
    private var task: URLSessionTask?
    private var lastLoadedPage: Int?
    private let perPage = 10
    
    // MARK: - Like / Unlike
    func changeLike(photoId: String, isLike: Bool, _ completion: @escaping (Result<Void, Error>) -> Void) {
            print(" [ImagesListService] Отправляем запрос на изменение лайка: \(photoId) -> \(isLike)")
            
            guard let request = makeChangeLikeRequest(photoId: photoId, isLike: isLike) else {
                print("[ImagesListService] Не удалось создать запрос")
                completion(.failure(NetworkError.invalidRequest))
                return
            }

            print(" [ImagesListService] Запрос создан, отправляем...")
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                print(" [ImagesListService] Получен ответ от сервера")
                
                if let error = error {
                    self.logError(method: "changeLike", errorType: String(describing: type(of: error)), params: "photoId=\(photoId) isLike=\(isLike)")
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    let status = httpResponse.statusCode
                    print(" [ImagesListService] HTTP статус: \(status)")

                    guard 200..<300 ~= status else {
                        self.logError(method: "changeLike", errorType: "HTTPStatusCode(\(status))", params: "photoId=\(photoId) isLike=\(isLike)")
                        DispatchQueue.main.async {
                            completion(.failure(NetworkError.httpStatusCode(status)))
                        }
                        return
                    }
                }

                print("[ImagesListService.changeLike] success 2xx")
                DispatchQueue.main.async {
                    if let index = self.photos.firstIndex(where: { $0.id == photoId }) {
                        var updatedPhotos = self.photos
                        updatedPhotos[index].isLiked = isLike
                        self.photos = updatedPhotos

                        NotificationCenter.default.post(
                            name: ImagesListService.didChangeNotification,
                            object: self,
                            userInfo: ["photos": self.photos]
                        )
                    }
                    completion(.success(()))
                }
            }
            
            print(" [ImagesListService] Задача запущена")
            task.resume()
        }

    private func makeChangeLikeRequest(photoId: String, isLike: Bool) -> URLRequest? {
        let url = Constants.defaultBaseURL
            .appendingPathComponent("photos")
            .appendingPathComponent(photoId)
            .appendingPathComponent("like")

        print(" [ImagesListService] Создаем запрос на URL: \(url)")

        var request = URLRequest(url: url)
        request.httpMethod = isLike ? "POST" : "DELETE"
        print(" [ImagesListService] HTTP метод: \(request.httpMethod ?? "nil")")

        guard let token = OAuth2TokenStorage.shared.token else {
            logError(method: "makeChangeLikeRequest",
                     errorType: "MissingToken",
                     params: "photoId=\(photoId)")
            return nil
        }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

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
            logError(method: "fetchPhotosNextPage", errorType: "InvalidRequest", params: "page=\(nextPage)")
            return
        }

        let task = URLSession.shared.objectTask(for: request) { [weak self] (result: Result<[PhotoResult], Error>) in
            guard let self else { return }
            switch result {
            case .success(let photoResults):
                print("[ImagesListService] Получено \(photoResults.count) фото для страницы \(nextPage)")
                self.handleSuccess(photoResults, nextPage: nextPage)
            case .failure(let error):
                self.logError(method: "fetchPhotosNextPage", errorType: String(describing: type(of: error)), params: "page=\(nextPage)")
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

        DispatchQueue.main.async {
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
            welcomeDescription: result.description,
            thumbImageURL: result.urls.small,
            largeImageURL: result.urls.full,
            isLiked: result.likedByUser ?? false
        )
    }

    private func makePhotosRequest(page: Int) -> URLRequest? {
        guard var urlComponents = URLComponents(url: Constants.defaultBaseURL, resolvingAgainstBaseURL: false) else {
            return nil
        }
        urlComponents.path = "/photos"
        urlComponents.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "order_by", value: "latest"),
            URLQueryItem(name: "per_page", value: String(perPage))
        ]

        guard let url = urlComponents.url else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        if let token = OAuth2TokenStorage.shared.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            request.setValue("Client-ID \(Constants.accessKey)", forHTTPHeaderField: "Authorization")
        }

        return request
    }
    
    func clearPhotos() {
            photos.removeAll()
            lastLoadedPage = nil
            print("[ImagesListService] Список изображений очищен")
        }

    private func logError(method: String, errorType: String, params: String) {
        print("[ImagesListService.\(method)]: \(errorType) \(params)")
    }
}
