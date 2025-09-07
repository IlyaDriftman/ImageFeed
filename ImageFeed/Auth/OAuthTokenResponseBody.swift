struct OAuthTokenResponseBody: Decodable {
    let accessToken: String
    let tokenType: String
    let refreshToken: String
    let scope: String
    let createdAt: Int
    let userId: Int
    let username: String
}
