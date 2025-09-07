@testable import ImageFeed

final class StubProfileService: ProfileServiceProtocol {
    var profile: Profile?
    init(profile: Profile? = nil) { self.profile = profile }
}

final class StubProfileImageService: ProfileImageServiceProtocol {
    var avatarURL: String?
    init(avatarURL: String? = nil) { self.avatarURL = avatarURL }
}

final class StubProfileLogoutService: ProfileLogoutServiceProtocol {
    private(set) var logoutCalled = false
    func logout() { logoutCalled = true }
}
