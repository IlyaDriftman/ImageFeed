import UIKit

class SingleImageViewController: UIViewController {
    @IBOutlet var imageView: UIImageView!
    
    @IBOutlet var scrollView: UIScrollView!
    var image: UIImage? {
        didSet {
            guard isViewLoaded, let image else { return }

            imageView.image = image
            imageView.frame.size = image.size
            rescaleAndCenterImageInScrollView(image: image)
        }
    }
    
    @IBAction func didTapShareButton(_ sender: Any) {
        guard let image else { return }
        let share = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        present(share, animated: true, completion: nil)
    }
   
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.delegate = self
        
        scrollView.minimumZoomScale = 0.1
        scrollView.maximumZoomScale = 1.25
        
        guard let image else { return }
        imageView.image = image
        imageView.frame.size = image.size
        rescaleAndCenterImageInScrollView(image: image)
    }
    private func rescaleAndCenterImageInScrollView(image: UIImage) {
        view.layoutIfNeeded()

        let scrollSize = scrollView.bounds.size
        let imageSize = image.size

        let scale = scrollSize.height / imageSize.height
        let newWidth = imageSize.width * scale
        let newHeight = scrollSize.height

        imageView.frame = CGRect(x: 0, y: 0, width: newWidth, height: newHeight)
        scrollView.contentSize = imageView.frame.size

        scrollView.setZoomScale(1.0, animated: false)

        let offsetX = max((newWidth - scrollSize.width) / 2, 0)
        let offsetY = max((newHeight - scrollSize.height) / 2, 0)
        scrollView.contentOffset = CGPoint(x: offsetX, y: offsetY)

        let horizontalInset = max((scrollSize.width - newWidth) / 2, 0)
        let verticalInset = max((scrollSize.height - newHeight) / 2, 0)
        scrollView.contentInset = UIEdgeInsets(top: verticalInset, left: horizontalInset, bottom: verticalInset, right: horizontalInset)
    }

   
    
    @IBAction func didTapBackButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
extension SingleImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
         
        return imageView
    }
}
