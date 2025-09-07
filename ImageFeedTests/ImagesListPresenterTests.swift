@testable import ImageFeed
import XCTest

final class ImagesListPresenterTests: XCTestCase {
    private func makePhoto(id: String = "1",
                           liked: Bool = false) -> Photo {
        Photo(id: id,
              size: .init(width: 10, height: 10),
              createdAt: nil,
              thumbImageURL: "",
              largeImageURL: "",
              isLiked: liked)
    }

    func test_viewDidLoad_callsFetchNextPage() {
       
        let service = StubImagesListService()
        let viewSpy = ImagesListViewSpy()
        let sut     = ImagesListPresenter(service: service)
        sut.view    = viewSpy

        sut.viewDidLoad()

        XCTAssertTrue(service.fetchNextPageCalled,
                      "Presenter должен запрашивать первую страницу")
    }

    func test_handleUpdate_insertsRows() {
        
        let service = StubImagesListService()
        let viewSpy = ImagesListViewSpy()
        let sut     = ImagesListPresenter(service: service)
        sut.view    = viewSpy
        sut.viewDidLoad()

        let first  = makePhoto(id: "1")
        service.photos = [first]
        NotificationCenter.default.post(
            name: StubImagesListService.didChangeNotification,
            object: service)

        XCTAssertEqual(viewSpy.inserted, [IndexPath(row: 0, section: 0)],
                       "Presenter должен вставить первую строку")
    }

    func test_didTapLike_flipsLikeAndReloads() {
    
        let photo   = makePhoto(id: "42", liked: false)
        let service = StubImagesListService()
        service.photos = [photo]

        let viewSpy = ImagesListViewSpy()
        let sut     = ImagesListPresenter(service: service)
        sut.view    = viewSpy

        sut.didTapLike(at: IndexPath(row: 0, section: 0))

        XCTAssertTrue(viewSpy.progressShown)
        XCTAssertTrue(viewSpy.progressHidden)
        XCTAssertEqual(service.likeRequest?.id, "42")
        XCTAssertTrue(viewSpy.reloaded.contains(IndexPath(row: 0, section: 0)))
    }
}
