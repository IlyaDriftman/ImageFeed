import Kingfisher
import UIKit

protocol ImagesListCellDelegate: AnyObject {
    func imageListCellDidTapLike(_ cell: ImagesListCell)
}

final class ImagesListCell: UITableViewCell {
    static let reuseIdentifier = "ImagesListCell"
    @IBOutlet var likeButton: UIButton!
    @IBOutlet var cellImage: UIImageView!
    @IBOutlet var dateLabel: UILabel!

    weak var delegate: ImagesListCellDelegate?

    func configure(imageURL: String, date: String, isLiked: Bool) {
        dateLabel.text = date

        let likeImage =
            isLiked
            ? UIImage(resource: .likeOn)
            : UIImage(resource: .likeOff)
        likeButton.setImage(likeImage, for: .normal)
        likeButton.accessibilityIdentifier =
            isLiked ? "like button on" : "like button off"
        print(
            "[ImagesListCell] Настроили лайк изображение: \(isLiked ? "like_on" : "like_off"), identifier: \(likeButton.accessibilityIdentifier ?? "nil")"
        )
        cellImage.contentMode = .center
        cellImage.clipsToBounds = true
        guard let url = URL(string: imageURL) else {
            cellImage.image = UIImage(named: "placeholder")
            return
        }
        cellImage.kf.setImage(
            with: url,
            placeholder: UIImage(named: "placeholder"),
            options: [.transition(.fade(0.2))]
        ) { [weak self] _ in
            self?.cellImage.contentMode = .scaleAspectFill
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cellImage.image = nil
        cellImage.kf.cancelDownloadTask()
        cellImage.contentMode = .center
        dateLabel.text = nil
        likeButton.setImage(nil, for: .normal)
        likeButton.accessibilityIdentifier = nil
        likeButton.isEnabled = true
        cellImage.backgroundColor = .clear
    }

    func setIsLiked(_ isLiked: Bool) {
        print("[ImagesListCell] setIsLiked вызван с: \(isLiked)")
        let image =
            isLiked
            ? UIImage(resource: .likeOn)
            : UIImage(resource: .likeOff)
        likeButton.setImage(image, for: .normal)
        likeButton.accessibilityIdentifier =
            isLiked ? "like button on" : "like button off"
        print(
            "[ImagesListCell] Установлено изображение: \(isLiked ? "like_on" : "like_off"), identifier: \(likeButton.accessibilityIdentifier ?? "nil")"
        )
    }

    @IBAction private func likeButtonClicked(_ sender: Any) {
        print("[ImagesListCell] Кнопка лайка нажата")
        likeButton.isEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.likeButton.isEnabled = true
        }
        delegate?.imageListCellDidTapLike(self)
    }
}
