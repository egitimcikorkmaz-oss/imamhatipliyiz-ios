# İmam Hatipliyiz iOS - Codemagic başlangıç derlemesi

Bu paket, kullanıcının sağladığı 8 SwiftUI kaynak dosyasını içerir.

## GitHub yükleme
ZIP'i açın ve içindeki 8 `.swift` dosyası, `project.yml`, `codemagic.yaml` ve `README.md` dosyalarını GitHub deposunun **ana dizinine** yükleyin. ZIP dosyasını tek başına yüklemeyin.

## Codemagic
`main` dalında `codemagic.yaml` algılandıktan sonra `ios-simulator-check` iş akışını başlatın. Bu iş akışı XcodeGen ile `.xcodeproj` üretir ve imzasız simulator derlemesi yapar. `.ipa` veya TestFlight yüklemesi YAPMAZ.

## Notlar
- Xcode derlemesi bu ortamda çalıştırılmadı. Derleme hataları Codemagic günlüklerinden incelenmelidir.
- App Store uygulama simgesi henüz eklenmedi; son simge seçildikten sonra asset catalog oluşturulacaktır.
- `tr.com.imamhatipliyiz.app` Bundle ID Apple Developer hesabında kayıtlı olmalıdır.
- WordPress API ve güvenli oturum gerçek cihazda ayrıca test edilmelidir.
- API anahtarı, parola, `.p8` veya sertifika dosyalarını GitHub'a koymayın.
