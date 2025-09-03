import UIKit

protocol ImagesListViewProtocol: AnyObject {
    func reloadRows(at indexPaths: [IndexPath])
    func insertRows(at indexPaths: [IndexPath])
    func showLikeError(message: String)
    func showBlockingHUD()
    func hideBlockingHUD()
    func updatePhotos(_ photos: [Photo])
    func updatePhotosAndReload(_ photos: [Photo])
}

protocol ImagesListServiceProtocol: AnyObject {
    var photos: [Photo] { get }
    static var didChangeNotification: Notification.Name { get }
    func fetchPhotosNextPage()
    func changeLike(
        photoId: String,
        isLike: Bool,
        _ completion: @escaping (Result<Void, Error>) -> Void
    )
}

final class ImagesListViewController: UIViewController,
    ImagesListViewProtocol
{

    func insertRows(at indexPaths: [IndexPath]) {
        print(
            "[ImagesListViewController] insertRows вызван для \(indexPaths.count) строк"
        )
        guard tableView != nil else {
            print("[ImagesListViewController] tableView is nil в insertRows")
            return
        }
        tableView.performBatchUpdates {
            tableView.insertRows(at: indexPaths, with: .automatic)
        }
    }

    func reloadRows(at indexPaths: [IndexPath]) {
        print("[ImagesListViewController] reloadRows вызван для \(indexPaths)")

        guard tableView != nil else {
            print("[ImagesListViewController] tableView is nil в reloadRows")
            return
        }

        let servicePhotos = ImagesListService.shared.photos
        print(
            "[ImagesListViewController] Синхронизируем данные: текущий count=\(photos.count), service count=\(servicePhotos.count)"
        )

        if servicePhotos.count >= photos.count {
            self.photos = Array(servicePhotos.prefix(photos.count))
            print(
                "[ImagesListViewController] Данные обновлены до \(photos.count) фотографий"
            )
        }

        tableView.reloadRows(at: indexPaths, with: .automatic)
    }

    func showLikeError(message: String) {
        let alert = UIAlertController(
            title: "Ошибка",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    func showBlockingHUD() { UIBlockingProgressHUD.show() }
    func hideBlockingHUD() { UIBlockingProgressHUD.dismiss() }

    func updatePhotos(_ photos: [Photo]) {
        print(
            "[ImagesListViewController] updatePhotos вызван с \(photos.count) фотографиями"
        )
        self.photos = photos
    }

    func updatePhotosAndReload(_ photos: [Photo]) {
        print(
            "[ImagesListViewController] updatePhotosAndReload вызван с \(photos.count) фотографиями"
        )
        self.photos = photos
        guard tableView != nil else {
            print(
                "[ImagesListViewController] tableView is nil в updatePhotosAndReload"
            )
            return
        }
        tableView.reloadData()
    }

    @IBOutlet var tableView: UITableView!
    private let showSingleImageSegueIdentifier = "ShowSingleImage"
    private var photos: [Photo] = []
    private var imagesObserver: NSObjectProtocol?
    private var displayedPhotosCount = 0
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()

    private var presenter: ImagesListPresenterProtocol!

    func configure(_ presenter: ImagesListPresenterProtocol) {
        self.presenter = presenter
        presenter.view = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.contentInset = UIEdgeInsets(
            top: 12,
            left: 0,
            bottom: 12,
            right: 0
        )
        tableView.register(
            UINib(nibName: "ImagesListCell", bundle: nil),
            forCellReuseIdentifier: ImagesListCell.reuseIdentifier
        )

        presenter.viewDidLoad()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    deinit {
        if let token = imagesObserver {
            NotificationCenter.default.removeObserver(token)
        }
    }

    private func updateTableViewAnimated() {
        displayedPhotosCount = photos.count
        tableView.reloadData()
    }

}

extension ImagesListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int)
        -> Int
    {
        let count = photos.count
        print(
            "[ImagesListViewController] numberOfRowsInSection возвращает: \(count)"
        )
        return count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
        -> UITableViewCell
    {
        print(
            "[ImagesListViewController] cellForRowAt вызван для \(indexPath), photos.count=\(photos.count)"
        )

        guard indexPath.row < photos.count else {
            print(
                "[ImagesListViewController] indexPath.row (\(indexPath.row)) >= photos.count (\(photos.count))"
            )
            return UITableViewCell()
        }

        let cell = tableView.dequeueReusableCell(
            withIdentifier: ImagesListCell.reuseIdentifier,
            for: indexPath
        )

        guard let imageListCell = cell as? ImagesListCell else {
            print(
                "[ImagesListViewController] Не удалось привести к ImagesListCell, тип: \(type(of: cell))"
            )
            return UITableViewCell()
        }

        imageListCell.prepareForReuse()
        imageListCell.delegate = self

        let photo = photos[indexPath.row]
        let dateString = dateFormatter.string(from: photo.createdAt ?? Date())
        print("[ImagesListViewController] Форматированная дата: \(dateString)")

        imageListCell.configure(
            imageURL: photo.thumbImageURL,
            date: dateString,
            isLiked: photo.isLiked
        )

        return imageListCell
    }

    func tableView(
        _ tableView: UITableView,
        willDisplay cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        print(
            "[ImagesListViewController] willDisplay cell at row \(indexPath.row), total photos: \(photos.count)"
        )
        presenter.willDisplayCell(at: indexPath)
    }
}

extension ImagesListViewController: UITableViewDelegate {
    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        print(
            "[ImagesListViewController] didSelectRowAt \(indexPath), photos.count=\(photos.count)"
        )
        tableView.deselectRow(at: indexPath, animated: false)

        guard indexPath.row < photos.count else {
            print(
                "[ImagesListViewController] didSelectRowAt - indexPath.row (\(indexPath.row)) >= photos.count (\(photos.count))"
            )
            return
        }

        presenter.didSelectCell(at: indexPath)
        performSegue(
            withIdentifier: showSingleImageSegueIdentifier,
            sender: indexPath
        )
    }

    func tableView(
        _ tableView: UITableView,
        heightForRowAt indexPath: IndexPath
    ) -> CGFloat {
        guard indexPath.row < photos.count else {
            print(
                "[ImagesListViewController] heightForRowAt - indexPath.row (\(indexPath.row)) >= photos.count (\(photos.count))"
            )
            return 44.0
        }

        let photo = photos[indexPath.row]
        let insets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
        let width = tableView.bounds.width - insets.left - insets.right
        let scale = width / photo.size.width
        return photo.size.height * scale + insets.top + insets.bottom
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showSingleImageSegueIdentifier {
            guard
                let viewController = segue.destination
                    as? SingleImageViewController,
                let indexPath = sender as? IndexPath
            else {
                assertionFailure("Invalid segue destination")
                return
            }

            guard indexPath.row < photos.count else {
                print(
                    "[ImagesListViewController] prepare(for segue:) - indexPath.row (\(indexPath.row)) >= photos.count (\(photos.count))"
                )
                print(
                    "[ImagesListViewController] Отменяем segue из-за некорректного индекса"
                )
                return
            }

            let imageURL = photos[indexPath.row].largeImageURL
            viewController.imageURL = imageURL
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }

}

extension ImagesListViewController: ImagesListCellDelegate {
    func imageListCellDidTapLike(_ cell: ImagesListCell) {
        print("[ImagesListViewController] Тап по лайку в ячейке")

        guard let indexPath = tableView.indexPath(for: cell) else {
            print(
                "[ImagesListViewController] Не удалось найти indexPath для ячейки"
            )
            return
        }

        print("[ImagesListViewController] IndexPath найден: \(indexPath)")

        guard indexPath.row < photos.count else {
            print(
                "[ImagesListViewController] IndexPath.row (\(indexPath.row)) >= photos.count (\(photos.count))"
            )
            return
        }

        let photo = photos[indexPath.row]
        print(
            "[ImagesListViewController] Текущее состояние лайка для фото \(photo.id): \(photo.isLiked)"
        )

        presenter.didTapLike(at: indexPath)
    }

}

extension ImagesListService: ImagesListServiceProtocol {}
