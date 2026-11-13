# İmam Hatipliyiz – Ortak üyelik / iOS API 0.8 + iOS 0.9 (test adayı)

## Kurulum (önce yedek + test ortamı)
1. Mevcut WordPress dosya ve veritabanı yedeğini alın. Canlı kullanıcı bilgileriyle test yapmayın.
2. Bağımsız Üyelik v2.1.0 eklentisini **koruyun**; değiştirmeyin.
3. Eski pasif `İmam Hatipliyiz iOS API - Güvenli Okul Köprüsü` v0.7 yerine bu paketteki v0.8 eklentisini güncelleyin ve test ortamında etkinleştirin. Aynı anda iki kopya etkinleştirmeyin.
4. Yönetim panelinde iOS Okul Yönetimi üzerinden bir TEST üyesine okul onayı ve uygun personel rolü verin. Roller kullanıcı tarafından seçilerek yetki kazanmaz.
5. iOS kaynak kodunu GitHub `main` dalına güncelleyin. `project.yml` sürümü 0.9.0 (6). Codemagic ile derleyin.
6. TestFlight'ta Profilim web girişini kullanın. Girişten sonra yerel Profilim üye numarası ve doğrulanmış rolü göstermeli. Mesajlar yalnızca onaylı öğretmen/yönetici için açılır. Alıcı üye numarasını kullanarak test mesajı gönderin.
7. Web oturumundan çıkış yapınca native API token'ı sonraki API isteğinde geçersiz olmalıdır. Native `Güvenli çıkış yap` web çerezlerini de temizler.

## Teknik yapı
- Web giriş: mevcut `IHM_Auth` üyelik çerezi (`HttpOnly`, `Secure`).
- `GET /wp-json/ih-ios/v1/bridge-nonce`: girişli web oturumunda CSRF değeri.
- `POST /wp-json/ih-ios/v1/web-bridge`: aynı origin, CSRF ve okul onayı gerektirir; 60 saniyelik tek kullanımlık kod.
- `POST /wp-json/ih-ios/v1/exchange`: kodu atomik tüketir; native bearer token döner. Kod yalnızca `WKWebView` ana çerçevesinden iOS'a aktarılır; token web JavaScript'ine aktarılmaz.
- `GET /me`, `GET/POST /messages`, `POST /logout`: native token ve okul yetkisi doğrulaması. Native token, kaynak web oturumuna bağlanır ve web oturumu sonlanınca geçersiz olur.
- iOS token Keychain'de saklanır; WordPress kullanıcı veritabanı değiştirilmez; API kendi onay, token ve mesaj tablolarını kullanır.

## Sınırlamalar / güvenlik kontrolü
- **Henüz gerçek sunucu veya iOS cihazında doğrulanmadı.** PHP sözdizimi kontrol edildi; Xcode/Codemagic derlemesi yapılmadı.
- Web oturumunun arka planda zaman aşımı native token'ı da etkiler; yeniden giriş gerekebilir.
- Alıcı listesi / kişi arama arayüzü henüz yok: onaylı personelin üye numarası elle girilir.
- WordPress REST güvenlik eklentisi, WAF veya önbellek bu endpoint'leri engelleyebilir. API oturum yanıtlarını önbelleğe almayın.
- Öğrenci/veli mesajlaşması bilerek kapalıdır; personel dışına açmadan önce çocuk güvenliği ve erişim kuralları tasarlanmalıdır.
- Üretime almadan önce güvenlik incelemesi, oturum eşzamanlılığı ve SMS/üyelik regresyon testleri yapılmalıdır.
