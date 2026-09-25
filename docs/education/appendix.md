# 8. Xcode ayarları ve yardımcı dosyalar

project.pbxproj, Xcode projesinin hedeflerini, dosya gruplarını, derleme aşamalarını ve ayarlarını tutar. Buradaki uzun kimlikler proje nesnelerini birbirine bağlar; iş mantığı değildir. Genellikle Xcode üzerinden değiştirilir. Uygulama, model testleri ve UI testleri ayrı hedeflerdir; Debug ve Release için tekrar eden ayarlar bulunması bu yüzden normaldir.

| Ayar / dosya | Mevcut değer veya rol | Geliştirici için anlamı |
| --- | --- | --- |
| SDKROOT | macosx | macOS SDK’sı ile derlenir. |
| SUPPORTED_PLATFORMS | macosx | Proje adı iOS desteği anlamına gelmez. |
| MACOSX_DEPLOYMENT_TARGET | 14.0 | Desteklenen en eski macOS sürümüdür; kullanılan SDK sürümüyle aynı kavram değildir. |
| SWIFT_VERSION | 5.0 | Swift dil uyumluluk modu; derleyici sürüm numarası değildir. |
| PRODUCT_BUNDLE_IDENTIFIER | test-app-ident.ios-test | Uygulamayı tanımlayan teknik kimliktir; test hedefleri ayrı sonekler taşır. |
| CODE_SIGN_STYLE | Automatic | İmzalama yönetimi Xcode’a bırakılır; dağıtıma hazır sertifika bulunduğunu garanti etmez. |
| GENERATE_INFOPLIST_FILE | YES | Uygulama metadata dosyası derleme ayarlarından üretilir. |
| ASSETCATALOG_COMPILER_APPICON_NAME | AppIcon | Uygulama simgesi olarak kullanılacak asset setini seçer. |
| ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME | AccentColor | Global vurgu asset adıdır; ContentView ayrıca kendi mor rengini tanımlar. |
| Assets.xcassets | Asset kataloğu | Simge ve renk kaynaklarını Xcode’a tanıtır. |
| Preview Content | Önizleme kaynak grubu | Tasarım sırasında kullanılabilecek asset alanıdır; görev deposu değildir. |
| README.md | Proje giriş belgesi | Kurulum ve kullanım anlatır; bu PDF kod öğretimine odaklanır. |
| docs/screenshots | İki tema görseli | Gerçek SwiftUI görünümünden örnek görevlerle alınmış render çıktılarıdır. |

## 8.1. AppIcon Contents.json nasıl okunur?

AppIcon.appiconset/Contents.json dosyasındaki images dizisi, macOS simgesi için çeşitli boyut ve ölçekleri eşler. Her kayıttaki filename PNG dosyasını, idiom: mac hedef ailesini, size mantıksal boyutu, scale ise piksel ölçeğini belirtir. Örneğin size: 16x16 ve scale: 2x, 32 × 32 piksel görsele karşılık gelir. Bu nedenle aynı piksel boyutunun farklı mantıksal kullanım rolleri olabilir.

16, 32, 128, 256 ve 512 punto boyutları için 1x ve 2x kayıtlar bulunur. info içindeki author: xcode, asset metadata üreticisini; version: 1 ise bu metadata biçiminin sürümünü ifade eder. Bunlar uygulamanın ürün sürüm numarası değildir. Binary PNG dosyaları kod satırı olarak açıklanamaz; katalog içindeki rolleri açıklanır.

## 8.2. .gitignore dosyasının beş satırı

| Satır | Desen | Neden dışarıda tutulur? |
| --- | --- | --- |
| 1 | .DS_Store | Finder’ın klasör görünüm metadata’sı kaynak kod değildir. |
| 2 | DerivedData/ | Xcode’un yeniden üretilebilir ara derleme verileri. |
| 3 | build/ | Yerel derleme çıktıları. |
| 4 | *.xcuserstate | Kullanıcıya özgü IDE pencere/oturum durumu. |
| 5 | xcuserdata/ | Geliştiriciye özgü Xcode kullanıcı ayarları. |

.gitignore, daha önce Git tarafından izlenen dosyaları kendiliğinden takipten çıkarmaz; esas olarak izlenmeyen eşleşen dosyaların eklenmesini engeller. Projedeki paylaşılan yapılandırmalar ile kişisel IDE tercihlerini ayırmak amaçlanır.

# 9. Testleri nasıl yorumlamalı?

Bir testin amacı “uygulama açıldı” ile “doğru çalışıyor” ifadelerini ayırmaktır. Model testleri UI’yı açmadan dosya ve veri davranışını sınar. UI testleri ise çalışan uygulamayı dışarıdan yönetir. Bu projede birinci grup daha somut davranış kontrolleri içerirken ikinci grup ağırlıkla Xcode şablonunun açılış ve ölçüm akışıdır.

| Davranış | Mevcut kanıt | Sınır |
| --- | --- | --- |
| Boş görev reddi | items.isEmpty beklentisi | Boş yeniden adlandırma ayrıca sınanmıyor. |
| Başlık temizliği | İlk görev başlığı karşılaştırması | Tüm Unicode boşluk durumları taranmıyor. |
| JSON kalıcılığı | Yeni TaskStore ile yeniden okuma | Gerçek süreç kapat/aç otomasyonu değil. |
| Tamamlama / düzenleme / silme | Yeniden yüklenen veri beklentileri | Bütün bulunamayan-kimlik durumları yok. |
| Önemli veri alanı | important: true sonrası yeniden okuma | toggleImportance ayrı test edilmemiş. |
| Bozuk veri koruması | Dosya baytlarının eşitliği | Yazma hatası ve disk doluluğu simülasyonu yok. |
| UI açılışı | XCUIApplication.launch | Görev ekleme, filtre, sheet ve arama assertion’ları yok. |
| Açılış performansı | XCTApplicationLaunchMetric | Kullanıcı etkileşim gecikmesini ölçmez. |

#expect, beklenen koşulun doğru olup olmadığını kaydeder. #require ise bir sonraki adımın devam edebilmesi için gerekli koşulu zorunlu kılar; örneğin ilk görev yoksa onun başlığını sınamak anlamsızdır. Swift Testing’in test tanımlama biçimi kaynak [8]’de açıklanır.

Geçici URL enjeksiyonu, test edilebilirliğin en önemli küçük tasarım kararlarından biridir. TaskStore(fileURL:) sayesinde test kendi dosyasını yaratabilir, bozuk veri koyabilir ve sonunda temizleyebilir. Bunun için ağ servisi, sahte UI veya karmaşık dependency injection çatısı gerekmez.

# 10. Öğrenmeyi pekiştiren uygulamalar

Bu alıştırmalar öneridir; projeye uygulanmadı. Önce beklenen davranışı yaz, sonra kodu değiştir ve son olarak ilgili davranışı doğrula. Görsel değişikliklerde Canvas veya çalışan uygulama, veri davranışlarında model testi daha uygun geri bildirim verir.

## 10.1. Yerleşim deneyi

Görev satırındaki HStack’i geçici olarak VStack yap. Dört öğenin neden artık tek satır oluşturmadığını gözlemle. Sonra HStack’e dönüp spacing değerini 13’ten 24’e çıkar. padding aynı kalırken yalnızca çocuklar arası uzaklığın değiştiğini açıkla. Beklenen sonuç: Stack yönü geometrik ilişkiyi, spacing iç öğeler arasını, padding bütün satırın çevresini etkiler.

## 10.2. Yeni bir filtre

TaskFilter’a pending durumu ekleyip başlık, icon ve subtitle switch’lerini tamamla. matches içinde !item.isCompleted dön. ForEach(allCases) sayesinde düğmenin neden kendiliğinden üretildiğini açıkla. Beklenen sonuç: enum merkezli tasarım, seçenekleri tek yerde tanımlamaya yardım eder; iş kuralı yine matches içinde eklenmelidir.

## 10.3. Önemli işaretinin kalıcılığı

Geçici URL’li TaskStore oluştur, görev ekle, toggleImportance çağır ve aynı URL’den yeni store aç. isImportant değerini doğrula. İkinci kez değiştirip false olduğunun da kalıcı kaldığını sınayabilirsin. Beklenen sonuç: yalnızca UI yıldızını değil, gerçek dosya üzerinden davranışı doğrulamak.

## 10.4. Hata sonrası yeniden deneme tasarımı

Yazma hatasının storageError nedeniyle sonraki işlemleri engellediğini izle. Güvenli bir yeniden deneme API’sinin ne zaman hatayı temizleyeceğini tasarla. Okuma hatasında boş items listesini hemen kaydetmenin neden tehlikeli olduğunu açıkla. Beklenen sonuç: hata mesajını silmek ile verinin yeniden güvenle yazılabilir olması aynı şey değildir.

## 10.5. UI testini büyütmek

Önce testler için yalıtılmış bir görev dosyası sağla. Ardından erişilebilir adlarla Yeni görev alanına metin yaz, Görev ekle düğmesine bas ve başlığın göründüğünü doğrula. Sonra tamamla ve Tamamlananlar filtresini kontrol et. Beklenen sonuç: açılış testini gerçek kullanıcı senaryosuna dönüştürmek; mevcut kullanıcı verisini test verisiyle karıştırmamak.

## 10.6. Kısa öz değerlendirme

- HStack içinde Spacer neden dikey boşluk üretmez? Çünkü ana eksen yataydır.
- newTitle neden TaskStore.items içinde tutulmaz? Henüz kaydedilmemiş bir UI taslağıdır.
- Önemli görev tamamlanınca yıldızı neden veri modelinden silinmez? Filtre koşulu tamamlanmışı dışlar; toggleCompletion yalnızca isCompleted alanını değiştirir.
- MainActor neden dosya yazmayı hızlandırmaz? İzolasyon sağlar; senkron I/O’yu otomatik arka plan işi yapmaz.
- .atomic neden yedek değildir? Yazma stratejisini düzenler; eski sürümleri arşivlemez.
- Önizleme neden environmentObject ister? ContentView’in bağımlılığı önizlemede de aynıdır.
- sheet neden nil ile kapanır? Sunum durumu optional editingItem binding’ine bağlıdır.
- createdAt varken neden liste tarihe göre sıralanmaz? Mevcut sorted karşılaştırıcısı sadece isCompleted alanını kullanır.

# 11. Resmî kaynaklar ve belge üretimi

Anlatımın birincil kaynağı bu deponun Swift dosyalarıdır. Aşağıdaki bağlantılar API kavramlarını derinleştirmek içindir. İnceleme tarihi: 25 Eylül 2026. API sayfalarının bazıları JavaScript gerektirdiğinden otomatik erişimde yalnızca referans kabuğu görüntülenebilmiştir; proje davranışı doğrudan yerel koddan çıkarılmıştır.

[1] Apple — HStack: https://developer.apple.com/documentation/swiftui/hstack

[2] Apple — LazyVStack: https://developer.apple.com/documentation/swiftui/lazyvstack

[3] Apple — StateObject: https://developer.apple.com/documentation/swiftui/stateobject

[4] Apple — Managing model data in your app: https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app

[5] Swift — Closures: https://docs.swift.org/swift-book/documentation/the-swift-programming-language/closures/

[6] Apple — Eliminate data races using Swift Concurrency: https://developer.apple.com/videos/play/wwdc2022/110351/

[7] Apple — Data writing option, atomic: https://developer.apple.com/documentation/foundation/nsdata/writingoptions/atomic

[8] Swift — Defining test functions: https://docs.swift.org/latest/documentation/testing/definingtests/

## 11.1. PDF’nin nasıl üretildiği

Metin ve satır açıklamaları docs/education altında düzenlenebilir kaynak olarak tutulur. build_guide.py, kaynak satırlarını numaralarıyla okuyup açıklamalarla eşler; eksik açıklama varsa üretimi durdurur. PDF, Python ve ReportLab ile oluşturulur. Türkçe karakterler için TrueType fontlar PDF’ye gömülür. Pypdf ile sayfa/metin kontrolü, görsel olarak da örnek sayfa incelemesi yapılır. Bu PDF üretim araçları uygulamanın çalışma zamanı bağımlılığı değildir.

Bu belge eğitim amaçlı bir kaynak kod incelemesidir. Uygulama davranışında değişiklik yapmaz. Ekran görselleri mevcut SwiftUI arayüzünün örnek görevlerle oluşturulan açık ve koyu tema çıktılarıdır; kullanıcı görevlerini temsil etmez.
