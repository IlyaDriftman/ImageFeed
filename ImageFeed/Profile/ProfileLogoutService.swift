import Foundation
import WebKit

final class ProfileLogoutService {
    static let shared = ProfileLogoutService()
    
    private init() { }
    
    func logout() {
        cleanCookies()
        OAuth2TokenStorage.shared.token = nil
        ProfileService.shared.clearProfile()
        ProfileImageService.shared.clearAvatar()
        ImagesListService.shared.clearPhotos()
        NotificationCenter.default.post(
            name: .userDidLogout,
            object: nil
        )
        
        print("[ProfileLogoutService] Все данные пользователя очищены")
    }
    
    private func cleanCookies() {
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            records.forEach { record in
                WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
            }
        }
    }
}

extension Notification.Name {
    static let userDidLogout = Notification.Name("UserDidLogout")
}

extension ProfileLogoutService: ProfileLogoutServiceProtocol {}
