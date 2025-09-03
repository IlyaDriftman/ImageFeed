@testable import ImageFeed
import XCTest

final class ImagesListViewControllerTests: XCTestCase {

    func test_viewDidLoad_callsPresenter() {
        
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        let vc = storyboard.instantiateViewController(withIdentifier: "ImagesListViewController") as! ImagesListViewController
        let presenterSpy = ImagesListPresenterSpy()
        vc.configure(presenterSpy)

        vc.loadViewIfNeeded()

        XCTAssertTrue(presenterSpy.viewDidLoadCalled)
    }

    func test_didSelectRow_callsPresenter() {

        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        let vc = storyboard.instantiateViewController(withIdentifier: "ImagesListViewController") as! ImagesListViewController
        let presenterSpy = ImagesListPresenterSpy()
        vc.configure(presenterSpy)
        vc.loadViewIfNeeded()

        let testPhoto = Photo(id: "test", size: CGSize(width: 100, height: 100), createdAt: Date(), thumbImageURL: "test", largeImageURL: "test", isLiked: false)
        vc.updatePhotos([testPhoto])

        let index = IndexPath(row: 0, section: 0)
        vc.tableView(vc.tableView, didSelectRowAt: index)

        XCTAssertTrue(presenterSpy.didSelectCalled)
    }

    func test_willDisplay_callsPresenter() {

        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        let vc = storyboard.instantiateViewController(
            withIdentifier: "ImagesListViewController"
        ) as! ImagesListViewController
        let presenterSpy = ImagesListPresenterSpy()
        vc.configure(presenterSpy)
        vc.loadViewIfNeeded()

        vc.tableView.register(UITableViewCell.self,
                              forCellReuseIdentifier: "dummy")
        vc.tableView.dataSource = DummyDataSource()
        vc.tableView.reloadData()

        let indexPath = IndexPath(row: 0, section: 0)

        vc.tableView(vc.tableView,
                     willDisplay: UITableViewCell(),
                     forRowAt: indexPath)

        XCTAssertTrue(presenterSpy.willDisplayCalled)
    }
    func test_likeButtonTap_callsPresenter() {

            let storyboard = UIStoryboard(name: "Main", bundle: .main)
            let vc = storyboard.instantiateViewController(
                withIdentifier: "ImagesListViewController"
            ) as! ImagesListViewController

            let presenterSpy = ImagesListPresenterSpy()
            vc.configure(presenterSpy)
            vc.loadViewIfNeeded()
            
            let testPhoto = Photo(id: "test", size: CGSize(width: 100, height: 100), createdAt: Date(), thumbImageURL: "test", largeImageURL: "test", isLiked: false)
            vc.updatePhotos([testPhoto])
            vc.tableView.reloadData()
            vc.tableView.layoutIfNeeded()

            let indexPath = IndexPath(row: 0, section: 0)
            print("🔍 [Test] Количество секций: \(vc.tableView.numberOfSections)")
            print("🔍 [Test] Количество строк в секции 0: \(vc.tableView.numberOfRows(inSection: 0))")
            
            let rawCell = vc.tableView.cellForRow(at: indexPath)
            print("🔍 [Test] Получена ячейка: \(rawCell != nil ? "есть" : "nil")")
            print("🔍 [Test] Тип ячейки: \(type(of: rawCell))")
            
            guard let cell = rawCell as? ImagesListCell else {
                XCTFail("cell is nil – проверьте dataSource / register. Тип ячейки: \(type(of: rawCell))"); return
            }
        
            vc.imageListCellDidTapLike(cell)

            XCTAssertTrue(presenterSpy.didTapLikeCalled,
                          "VC должен вызывать didTapLike у презентера")
        }
}

// MARK: - Test doubles
private final class DummyDataSource: NSObject, UITableViewDataSource {
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int { 1 }
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.dequeueReusableCell(withIdentifier: "dummy", for: indexPath)
    }
}
