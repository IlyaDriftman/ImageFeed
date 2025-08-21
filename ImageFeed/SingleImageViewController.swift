import UIKit
import Kingfisher

final class SingleImageViewController: UIViewController {
    @IBOutlet var imageView: UIImageView!
    
    @IBOutlet var scrollView: UIScrollView!
    
    private var isImageLoading = false
    private var isImageLoaded = false
    
    private let placeholderImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "placeholder")
        imageView.contentMode = .center
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    var imageURL: String?
    
    @IBAction private func didTapShareButton(_ sender: Any) {
        guard let image = imageView.image else { return }
        
        let activityViewController = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        
        present(activityViewController, animated: true)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupPlaceholder()
        imageView.image = nil
        print("viewDidLoad - imageView очищен")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !isImageLoading && !isImageLoaded {
            print(" Условие выполнено, вызываем loadImage")
            loadImage()
        } else {
            print("Пропускаем загрузку - isImageLoading: \(isImageLoading), isImageLoaded: \(isImageLoaded)")
        }
    }
    
    private func setupPlaceholder() {
        view.addSubview(placeholderImageView)
        view.bringSubviewToFront(placeholderImageView)
        NSLayoutConstraint.activate([
            placeholderImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            placeholderImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            placeholderImageView.widthAnchor.constraint(equalToConstant: 60),
            placeholderImageView.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        placeholderImageView.isHidden = false
    }
    
    private func setupUI() {
        scrollView.delegate = self
        scrollView.minimumZoomScale = 0.1
        scrollView.maximumZoomScale = 3.0
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.isHidden = true
    }
    
    private func loadImage() {
        guard !isImageLoading else { return }
        
        guard let imageURL = imageURL else {
            showError()
            return
        }
        
        guard let fullImageURL = URL(string: imageURL) else {
            showError()
            return
        }
        
        isImageLoading = true
        UIBlockingProgressHUD.show()
        
        imageView.kf.setImage(with: fullImageURL) { [weak self] result in
            UIBlockingProgressHUD.dismiss()
            guard let self = self else { return }
            self.isImageLoading = false
            
            switch result {
            case .success(let imageResult):
                self.isImageLoaded = true
                self.imageView.isHidden = false
                self.placeholderImageView.isHidden = true
                self.rescaleAndCenterImageInScrollView(image: imageResult.image)
                
            case .failure(let error):
                print("Ошибка загрузки: \(error)")
                
                if case .imageSettingError(let reason) = error,
                   case .notCurrentSourceTask = reason {
                    
                    if let loadedImage = self.imageView.image {
                        self.isImageLoaded = true
                        self.imageView.isHidden = false
                        self.placeholderImageView.isHidden = true
                        self.rescaleAndCenterImageInScrollView(image: loadedImage)
                    } else {
                        self.showError()
                    }
                    
                } else {
                    self.showError()
                }
            }
        }
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
    
    // MARK: - Error Handling
    private func showError() {
        let alert = UIAlertController(
            title: "Ошибка загрузки",
            message: "Не удалось загрузить изображение",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
    
    private func centerImageInScrollView() {
        let boundsSize = scrollView.bounds.size
        var frameToCenter = imageView.frame
        
        if frameToCenter.size.width < boundsSize.width {
            frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2
        } else {
            frameToCenter.origin.x = 0
        }
        
        if frameToCenter.size.height < boundsSize.height {
            frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2
        } else {
            frameToCenter.origin.y = 0
        }
        
        imageView.frame = frameToCenter
    }
    @IBAction func didTapBackButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

extension SingleImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerImageInScrollView()
    }
}
