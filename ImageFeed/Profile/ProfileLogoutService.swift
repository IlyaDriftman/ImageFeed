import Foundation
// Обязательный импорт
import WebKit

final class ProfileLogoutService {
   static let shared = ProfileLogoutService()
  
   private init() { }

   func logout() {
       // 1. Очищаем cookies и WebKit данные
               cleanCookies()
               
               // 2. Очищаем токен авторизации
               OAuth2TokenStorage.shared.token = nil
               
               // 3. Сбрасываем данные профиля
               ProfileService.shared.clearProfile()
               
               // 4. Сбрасываем аватарку
               ProfileImageService.shared.clearAvatar()
               
               // 5. Очищаем список изображений
               ImagesListService.shared.clearPhotos()
               
               // 6. Отправляем уведомление о выходе
               NotificationCenter.default.post(
                   name: .userDidLogout,
                   object: nil
               )
               
               print("[ProfileLogoutService] Все данные пользователя очищены")
   }

   private func cleanCookies() {
      // Очищаем все куки из хранилища
      HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
      // Запрашиваем все данные из локального хранилища
      WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
         // Массив полученных записей удаляем из хранилища
         records.forEach { record in
            WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
         }
      }
   }
}
// Расширение для уведомлений
extension Notification.Name {
    static let userDidLogout = Notification.Name("UserDidLogout")
}
    
