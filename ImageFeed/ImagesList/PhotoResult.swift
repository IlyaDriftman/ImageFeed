struct PhotoResult: Codable {
    let id: String
    let createdAt: String?        // Приходит ISO8601 строкой
    let width: Int
    let height: Int
    let likedByUser: Bool?
    let description: String?
    let urls: UrlsResult
    
    enum CodingKeys: String, CodingKey {
        case id
        case createdAt     = "created_at"
        case width, height
        case likedByUser   = "liked_by_user"
        case description
        case urls
    }
}
