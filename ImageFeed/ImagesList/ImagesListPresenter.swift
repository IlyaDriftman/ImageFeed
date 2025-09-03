import Foundation

protocol ImagesListPresenterProtocol: AnyObject {
    var view: ImagesListViewProtocol? { get set }

    func viewDidLoad()
    func willDisplayCell(at indexPath: IndexPath)
    func didSelectCell(at indexPath: IndexPath)
    func didTapLike(at indexPath: IndexPath)
}

final class ImagesListPresenter: ImagesListPresenterProtocol {
    func didSelectCell(at indexPath: IndexPath) {
       //
    }
    

    weak var view: ImagesListViewProtocol?
    private let service: ImagesListServiceProtocol
    private var photos: [Photo] { service.photos }
    private var observer: NSObjectProtocol?
    private var lastPhotosCount = 0

    init(service: ImagesListServiceProtocol = ImagesListService.shared) {
        self.service = service
    }

    func viewDidLoad() {
        print("[ImagesListPresenter] viewDidLoad вызван")
        observer = NotificationCenter.default.addObserver(
            forName: ImagesListService.didChangeNotification,
            object: service,
            queue: .main
        ) { [weak self] _ in
            print(
                "[ImagesListPresenter] Получена нотификация об изменении данных"
            )
            self?.handleUpdate()
        }
        print("[ImagesListPresenter] Вызываем fetchPhotosNextPage")
        lastPhotosCount = service.photos.count
        if !service.photos.isEmpty {
            print(
                "[ImagesListPresenter] Передаем существующие \(service.photos.count) фотографий"
            )
            view?.updatePhotosAndReload(service.photos)
        }
        service.fetchPhotosNextPage()
    }

    private func handleUpdate() {
        let oldCount = lastPhotosCount
        let newCount = service.photos.count
        print(
            "[ImagesListPresenter] handleUpdate: oldCount=\(oldCount), newCount=\(newCount), service.photos.count=\(service.photos.count)"
        )

        guard newCount > oldCount else {
            print(
                "[ImagesListPresenter] Нет новых данных для обновления (oldCount=\(oldCount), newCount=\(newCount))"
            )
            return
        }
        view?.updatePhotos(service.photos)
        let indexPaths = (oldCount..<newCount)
            .map { IndexPath(row: $0, section: 0) }
        print("[ImagesListPresenter] Вставляем строки: \(indexPaths)")
        view?.insertRows(at: indexPaths)
        lastPhotosCount = newCount
    }

    func willDisplayCell(at indexPath: IndexPath) {
        print(
            "[ImagesListPresenter] willDisplayCell: indexPath.row=\(indexPath.row), lastPhotosCount=\(lastPhotosCount)"
        )
        if indexPath.row == lastPhotosCount - 1 {
            print(
                "[ImagesListPresenter] Достигнут конец списка, загружаем следующую страницу"
            )
            service.fetchPhotosNextPage()
        }
    }

    func didTapLike(at indexPath: IndexPath) {
        print(
            "[ImagesListPresenter] didTapLike вызван для indexPath: \(indexPath)"
        )

        guard indexPath.row < photos.count else {
            print(
                "[ImagesListPresenter] IndexPath.row (\(indexPath.row)) >= photos.count (\(photos.count))"
            )
            return
        }

        let photo = photos[indexPath.row]
        let newLikeState = !photo.isLiked
        print(
            "[ImagesListPresenter] Фото \(photo.id) - изменяем лайк с \(photo.isLiked) на \(newLikeState)"
        )

        view?.showBlockingHUD()
        service.changeLike(photoId: photo.id, isLike: newLikeState) {
            [weak self] result in
            guard let self else { return }
            self.view?.hideBlockingHUD()

            print(
                "[ImagesListPresenter] Получен результат changeLike: \(result)"
            )

            switch result {
            case .success:
                print(
                    "[ImagesListPresenter] Лайк успешно изменен, обновляем UI"
                )
                self.view?.reloadRows(at: [indexPath])
            case .failure(let error):
                print("[ImagesListPresenter] Ошибка изменения лайка: \(error)")
                let errorMessage = self.mapErrorToUserMessage(error)
                self.view?.showLikeError(message: errorMessage)
            }
        }
    }
    
    // MARK: - Private Helpers
    private func mapErrorToUserMessage(_ error: Error) -> String {
        if case NetworkError.httpStatusCode(let statusCode) = error {
            switch statusCode {
            case 400:
                return "Неверный запрос. Попробуйте еще раз."
            case 401:
                return "Необходима авторизация. Войдите в аккаунт."
            case 403:
                return "Доступ запрещен. У вас нет прав для этого действия."
            case 404:
                return "Фотография не найдена."
            case 500...599:
                return "Ошибка сервера. Попробуйте позже."
            default:
                return "Ошибка сети. Проверьте подключение к интернету."
            }
        } else {
            return "Ошибка сети. Проверьте подключение к интернету."
        }
    }
}
