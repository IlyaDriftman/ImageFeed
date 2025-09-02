@testable import ImageFeed
import UIKit

// MARK: - View Spy
final class ImagesListViewSpy: ImagesListViewProtocol {
    private(set) var inserted: [IndexPath] = []
    private(set) var reloaded: [IndexPath] = []
    private(set) var likeErrorShown = false
    private(set) var progressShown  = false
    private(set) var progressHidden = false

    func insertRows(at indexPaths: [IndexPath]) { inserted = indexPaths }
    func reloadRows(at indexPaths: [IndexPath]) { reloaded = indexPaths }
    func showLikeError(message: String)         { likeErrorShown = true }
    func showBlockingHUD()                      { progressShown  = true }
    func hideBlockingHUD()                      { progressHidden = true }
    func updatePhotos(_ photos: [Photo])        { }
    func updatePhotosAndReload(_ photos: [Photo]) { }
}

// MARK: - Service Stub
final class StubImagesListService: ImagesListServiceProtocol {
    var photos: [Photo] = []
    static var didChangeNotification = ImagesListService.didChangeNotification
    private(set) var fetchNextPageCalled = false
    private(set) var likeRequest: (id: String, newValue: Bool)?

    func fetchPhotosNextPage() { fetchNextPageCalled = true }

    func changeLike(photoId: String,
                    isLike: Bool,
                    _ completion: @escaping (Result<Void, Error>) -> Void) {
        likeRequest = (photoId, isLike)
        if let index = photos.firstIndex(where: { $0.id == photoId }) {
            photos[index].isLiked = isLike
        }
        completion(.success(()))
    }
}

// MARK: - Presenter Spy (для проверки вызовов из VC)
final class ImagesListPresenterSpy: ImagesListPresenterProtocol {
    weak var view: ImagesListViewProtocol?

    private(set) var viewDidLoadCalled = false
    private(set) var willDisplayCalled = false
    private(set) var didSelectCalled   = false
    private(set) var didTapLikeCalled  = false

    func viewDidLoad() {
        viewDidLoadCalled = true
    }
    func willDisplayCell(at indexPath: IndexPath) {
        willDisplayCalled = true
    }
    func didSelectCell(at indexPath: IndexPath) {
        didSelectCalled = true
    }
    func didTapLike(at indexPath: IndexPath) {
        didTapLikeCalled = true
    }
}
