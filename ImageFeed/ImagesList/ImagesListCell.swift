import UIKit
import Kingfisher

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
        
        let likeImage = isLiked
            ? UIImage(named: "like_on")
            : UIImage(named: "like_off")
        likeButton.setImage(likeImage, for: .normal)
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
        likeButton.isEnabled = true
        cellImage.backgroundColor = .clear
    }
    
    func setIsLiked(_ isLiked: Bool) {
            let image = isLiked
                ? UIImage(named: "like_on")
                : UIImage(named: "like_off")
            likeButton.setImage(image, for: .normal)
        }
    
    @IBAction func likeButtonClicked(_ sender: Any) {
        delegate?.imageListCellDidTapLike(self)
    }
}
