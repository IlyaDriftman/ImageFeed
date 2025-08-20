struct PhotoResult: Codable {
    let id: String
    let createdAt: String?        // Приходит ISO8601 строкой
    let width: Int
    let height: Int
    let color: String?
    let blurHash: String?
    let likes: Int?
    let likedByUser: Bool?
    let description: String?
    let urls: UrlsResult

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt     = "created_at"
        case width, height, color
        case blurHash      = "blur_hash"
        case likes
        case likedByUser   = "liked_by_user"
        case description
        case urls
    }
}
