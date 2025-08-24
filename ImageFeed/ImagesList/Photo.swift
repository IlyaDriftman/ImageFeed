import Foundation

struct Photo {
    let id: String
    let size: CGSize
    let createdAt: Date?
    let thumbImageURL: String
    let largeImageURL: String
    let isLiked: Bool
}
