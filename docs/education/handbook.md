# 1. Bu rehberi nasıl okumalı?

Bu belge, temel programlama bilgisi olan fakat SwiftUI’ya yeni başlayan bir yazılımcı için hazırlanmıştır. Amaç yalnızca kodu Türkçeye çevirmek değil; veri, kullanıcı eylemi, yerleşim ve kalıcı kayıt arasındaki ilişkiyi açıklamaktır. Projenin adı dosyalarda ios_test olsa da çalıştırılan hedef macOS uygulamasıdır.

Kapsam: ios_testApp.swift, TaskStore.swift, ContentView.swift ve üç test dosyasının toplam 514 fiziksel satırı. Her satır özgün numarasıyla gösterilir; boş satırlar, yorumlar ve kapanışlar da atlanmaz. Xcode’un ürettiği project.pbxproj içindeki yüzlerce nesne kaydı ise satır satır değil, geliştirici açısından önemli ayarlar üzerinden açıklanır. Görseller ve JSON asset kayıtları ayrıca ele alınır.

Satır açıklamalarındaki “neden” ifadeleri, mevcut kodun sağladığı faydaya dayalı teknik yorumlardır. Özgün yazarın belgelenmemiş düşüncesini bildiğimiz anlamına gelmez. Açılıştaki Dock simgesi yenilemesinin amacı ise kaynak kod yorumunda açıkça belirtilmiştir.

Önerilen sıra: önce 2–6. bölümlerde kavramları öğren; sonra uygulama girişini, veri deposunu ve arayüzü bu sırayla oku. Testleri en son okuyarak uygulamanın hangi davranışlarının gerçekten doğrulandığını gör. Kaynak kod değiştikçe satır numaraları da değişir; bu PDF, üretildiği andaki dosyaların bir anlık görüntüsüdür.

## 1.1. Öğrenme hedefleri

- Bildirimsel arayüzün, elle görünüm güncellemekten farkını açıklamak.
- HStack, VStack ve ZStack arasında görsel ihtiyaca göre seçim yapmak.
- Geçici arayüz durumu ile kalıcı görev verisini birbirinden ayırmak.
- Bir düğmeye basılmasından JSON kaydına ve ekranın yenilenmesine kadar akışı izlemek.
- Closure, binding, optional, guard, protocol ve actor kavramlarını gerçek satırlarda tanımak.
- Bir testin neyi kanıtladığını ve neyi kanıtlamadığını ayırt etmek.

# 2. Uygulamanın büyük resmi

Odak, görev ekleme, önemli işaretleme, tamamlama, arama, filtreleme, düzenleme ve silme sunan küçük bir masaüstü uygulamasıdır. Uygulamada sunucu, oturum açma, ağ isteği veya bulut eşitlemesi bulunmaz. Kalıcı veri bir JSON dosyasındadır; arama metni ve seçili filtre gibi ekran tercihleri bu dosyaya yazılmaz.

![Odak açık tema: arayüzün genel görünümü](../screenshots/odak-light.png)

## 2.1. Dosyalar ve sorumluluklar

| Parça | Sorumluluğu | Burada yapılmayan iş |
| --- | --- | --- |
| ios_testApp.swift | Uygulamayı başlatır, pencereyi kurar, ortak TaskStore’u üretir. | Görev satırlarını çizmez. |
| TodoItem | Tek görevin kimliğini, başlığını, durumlarını ve tarihini tutar. | Dosyaya kendi kendine yazmaz. |
| TaskStore | Görev işlemlerini doğrular, JSON okur/yazar, değişikliği yayımlar. | Pencere veya düğme yerleşimi bilmez. |
| ContentView | Arayüzü, filtreyi, aramayı, giriş odağını ve düzenleme formunu yönetir. | JSON kodlama ayrıntısını uygulamaz. |
| ios_testTests | Depolama ve model davranışlarını geçici dosyalarla sınar. | Gerçek fare/klavye etkileşimi yapmaz. |
| ios_testUITests | Uygulama açılışı, performans ölçümü ve görüntü eki üretir. | Bütün özellikleri uçtan uca doğrulamaz. |

Bu yapı, görünüm ile veri işlemlerini ayırır. TaskStore hem gözlemlenebilir durum hem depolama sorumluluğu taşır; ContentView içinde de filtreleme mantığı vardır. Dolayısıyla projeyi katı, çok katmanlı bir MVVM uygulaması diye sunmak yerine, küçük uygulamaya uygun bir görünüm + ortak veri deposu tasarımı olarak okumak daha isabetlidir.

## 2.2. Veri akışı

```text
ios_testApp
    oluşturur: @StateObject TaskStore
    paylaşır:  .environmentObject(store)
                       |
                       v
ContentView: @EnvironmentObject store
    kullanıcı eylemi -> store.add / rename / toggle / delete
                       |
                       v
TaskStore.update
    doğrula -> kopyayı değiştir -> JSON yaz -> items değerini yayımla
                       |
                       v
SwiftUI, değişen duruma bağımlı arayüzü yeniden değerlendirir
```

TaskStore’un tek örneği uygulama düzeyinde sahiplenilir. WindowGroup üzerinden birden fazla pencere oluşturulursa görev deposu ortaktır. Her ContentView’in arama ve filtre gibi @State değerleri ise kendi görünüm kimliğine bağlı yerel durumudur. Ortak veri ile pencereye özgü sunum böyle ayrılır.

## 2.3. Somut senaryo: Önemli listesinden görev eklemek

1. Kullanıcı Önemli filtresini seçer; filter state’i .important olur.
2. TextField’a yazılan metin, $newTitle üzerinden newTitle değerine aktarılır.
3. Return veya ok düğmesi addTask() çağırır.
4. addTask, important: true ile store.add çağırır.
5. TaskStore başlığın dış boşluklarını temizler, boş başlığı reddeder.
6. update, dizinin kopyasına yeni görevi başa ekler ve JSON dosyasına yazar.
7. Yazma başarılıysa items güncellenir; hata varsa eski liste korunur.
8. Başarı yolunda taslak ve arama temizlenir, giriş alanı yeniden odaklanır.
9. Liste, sayaçlar ve ilerleme kartı kendi hesaplarını güncel durumdan üretir.

# 3. Kullanılan araçlar ve nedenleri

| Araç / teknoloji | Projedeki rolü | Neden uygun? |
| --- | --- | --- |
| Swift | Uygulama ve test dili | Tip güvenliği, optional ve protokollerle niyet açık yazılır. |
| SwiftUI | Bildirimsel arayüz çatısı | Durumdan arayüz üretir; küçük bileşenler birleştirilir. |
| AppKit | macOS platform API’leri | Dock simgesi ve yerel renk gibi masaüstüne özgü işleri sağlar. |
| Foundation | URL, Date, UUID, Data, FileManager, JSON | Küçük uygulama için gerekli sistem veri ve dosya araçları hazırdır. |
| ObservableObject / Published | Gözlemlenebilir durum | SwiftUI’ya görev verisinin değiştiğini bildirir; projede ayrı bir Combine iş hattı yazılmaz. |
| SF Symbols | Sistem simgeleri | Kontroller için ayrı PNG dosyaları taşımadan tutarlı simgeler sağlar. |
| Xcode / Canvas | Derleme, çalıştırma, önizleme | Apple platform hedeflerini ve SwiftUI önizlemesini yönetir. |
| Swift Testing | Model testleri | @Test ve beklenti makrolarıyla kısa davranış testleri yazılır. |
| XCTest / XCUITest | UI ve performans testleri | Çalışan uygulamayı başlatma, ölçme ve ekran görüntüsü alma imkânı sağlar. |
| Git | Kaynak sürüm takibi | Kod ve dokümantasyon değişiklikleri karşılaştırılabilir. |

Uygulama kaynaklarında üçüncü taraf paket bağımlılığı yoktur. JSON saklama, bu ölçekte ayrı bir veritabanı kurma gereksinimini azaltır. Karşılığında her değişiklikte bütün görev dizisi yeniden kodlanır ve yazılır. Büyük veri, sorgu, ilişkiler veya eşitleme gereksinimi doğarsa depolama tasarımı yeniden değerlendirilmelidir.

Proje minimum macOS 14 hedefler. SWIFT_VERSION = 5.0 ayarı Swift 5 dil uyumluluk modunu ifade eder; kullanılan derleyicinin kesin olarak Swift 5.0 olduğu anlamına gelmez. Kaynakta #Preview, switch ifadeleri ve Swift Testing gibi daha yeni araç zinciri özellikleri bulunduğu için tam Xcode 16 veya üzeri geliştirme ortamı uygundur.

## 3.1. Çalıştırma ve doğrulama

Xcode ile ios_test.xcodeproj açılır, ios_test şeması ve My Mac hedefi seçilir. Command+R uygulamayı, Command+U testleri çalıştırır. Canvas, ContentView’in #Preview bloğunu kullanır. Command Line Tools seçiliyse xcodebuild komutları tam Xcode’a yönlendirilmelidir; bu belge üretimi sistemdeki geliştirici dizini seçimini değiştirmez.

```sh
xcodebuild test \
  -project ios_test.xcodeproj \
  -scheme ios_test \
  -destination 'platform=macOS'
```

Bu rehber için uygulama testleri yeniden çalıştırılmadı. Test bölümleri mevcut test kodunun statik incelemesidir; bir testin bulunması veya burada açıklanması, son koşumda geçtiğinin kanıtı değildir.

# 4. SwiftUI yerleşimi: hangi Stack, neden?

SwiftUI’da bir görünümün body özelliği, o anki duruma göre nasıl görünmesi gerektiğini tarif eder. Geliştirici her metin değişikliğinde etiketi elle güncellemez. SwiftUI, kimlik ve bağımlılık bilgisiyle görünüm tanımlarını yeniden değerlendirir ve gerekli ekran güncellemelerini uygular. body’yi tek sefer çalışan bir çizim fonksiyonu gibi düşünmek yanıltıcıdır.

## 4.1. HStack: yatay ilişki

HStack çocuklarını yatay eksende yerleştirir. Odak’ın dış HStack’i sidebar ile ana paneli yan yana koyar. Görev satırındaki HStack ise daire, başlık, yıldız ve menüyü tek satırda toplar. Birimler birbirinin yanında anlamlı bir bütün oluşturduğu için yatay yerleşim seçilmiştir. Apple’ın HStack referansı için kaynak [1]’e bak.

```swift
HStack(spacing: 13) {
    // Tamamlama kontrolü
    // Esnek görev başlığı
    // Önemli düğmesi
    // İşlem menüsü
}
```

HStack’i VStack ile değiştirirsen aynı kontroller alt alta dizilir; ZStack ile değiştirirsen aynı bölgede üst üste yerleşir. Yani Stack seçimi bir hızlandırma numarası değil, öğeler arasındaki geometrik ilişkinin tarifidir. HStack tek başına otomatik satır kaydırma yapmaz; dar alanda metin ve kontrollerin sığması ayrıca düşünülmelidir.

## 4.2. VStack ve ZStack

VStack dikey gruplar için kullanılır: ana panelde header, progressCard, composer, taskList ve footer yukarıdan aşağıya gelir. alignment: .leading yatay hizayı, spacing: 26 ise komşu çocuklar arasındaki dikey uzaklığı belirler. “Dikey yığın” içindeki alignment’ın yine yatay bir hizayı belirlemesi sık karıştırılan noktadır.

ZStack katmanları üst üste bindirir. İlerleme halkasında soluk tam çember, mor kısmi çember ve ortadaki onay simgesi aynı merkezi paylaşır. Üçü aynı görselin katmanları olduğundan ZStack kullanılır. Arka plan yapmak için her zaman ZStack gerekmez; tek görünümün arkasına şekil eklemek için background daha doğrudan olabilir.

```text
HStack:  [ simge ] [ başlık          ] [ yıldız ]

VStack:  [ başlık                    ]
         [ açıklama                 ]
         [ giriş alanı              ]

ZStack:  [ arka halka + ilerleme yayı + merkez simgesi ]
```

## 4.3. Spacer, frame ve padding birbirinin yerine geçmez

Spacer, içinde bulunduğu yığının ana eksenindeki uygun boşluğu alır. HStack içinde sağdaki öğeleri sona iter; VStack içinde alt içeriği aşağı iter. Bu projede sidebar içindeki Spacer, motivasyon kartını aşağı taşırken footer içindeki Spacer kısayolu sağa taşır.

frame, görünümün yerleşimde talep ettiği alanı ve o alan içindeki hizasını etkiler. maxWidth: .infinity, ebeveynin verdiği uygun genişliğe yayılma isteğidir; sınırsız fiziksel ekran alanı oluşturmaz. width: 226 ise sidebar için belirli bir genişliktir. Gerçek pencere boyutu, ebeveynin boyut önerileri ve minimum sınırlar birlikte sonuç üretir.

padding, bir görünümün çevresine boşluk ekler. spacing, bir yığının çocukları arasındaki mesafedir. Aynı tasarımda ikisi birlikte kullanılabilir. Örneğin progressCard’daki HStack(spacing: 18) kart öğelerini ayırır; .padding(20) bütün kartın içeriğini dış sınırdan uzaklaştırır.

## 4.4. Modifier sırası neden önemlidir?

Modifier’lar zincir halinde yeni bir görünüm değeri oluşturur. Sıra özellikle boyut ve arka plan ilişkisini değiştirir. Kaynakta önce padding sonra background kullanılması, arka planın boşluk eklenmiş alanı da kaplamasını sağlar. Aşağıdaki örnekler eğitim amaçlıdır; uygulamaya eklenmiş kod değildir.

```swift
Text("Odak")
    .padding(16)
    .background(Color.purple)
// Mor alan metin + boşluğu kapsar.

Text("Odak")
    .background(Color.purple)
    .padding(16)
// Mor alan metnin arkasındadır; dış boşluk mor olmaz.
```

foregroundStyle içerik çizimini, background içerik arkasını, clipShape ise çizimin görünür sınırını etkiler. tint, onu kullanan alt kontrollere vurgu rengi sağlar. Bu dört API aynı şeyi yapmaz. Mevcut projede mor tint düğmelere yön verirken, önemli yıldız açıkça turuncu foregroundStyle kullanır.

## 4.5. ScrollView, LazyVStack ve ForEach

ScrollView kaydırma davranışını, LazyVStack dikey ve ihtiyaç oldukça üretilen içeriği, ForEach ise veriden kimlikli görünüm üretimini sağlar. Birlikte çalışırlar ama sorumlulukları ayrıdır. TodoItem.id, görev başlığı değişse veya sırası farklılaşsa da satırın aynı görev olarak tanınmasını sağlar. Kaynak [2], tembel dikey yerleşimin API referansıdır.

Bu projede tembel olan görünüm üretimidir. visibleItems hesaplaması yine görev dizisini filtreler ve sıralar; JSON dosyasının tamamı belleğe alınır. Dolayısıyla LazyVStack eklemek, veri işleme maliyetlerinin tamamını ortadan kaldırmaz. Küçük liste için basitlik uygundur; büyük listede ölçümle karar verilmelidir.

# 5. Swift dili ve durum yönetimi

## 5.1. Sık görülen sözdizimi

| Yazım | Anlamı | Projedeki örnek |
| --- | --- | --- |
| let / var | Yeniden atanamayan / atanabilen bağ | accent sabit, filter değişken. |
| struct / class | Değer türü / referans türü | TodoItem verisi, TaskStore ortak nesnesi. |
| enum | Sınırlı olası durumlar | TaskFilter üç filtreyi sınırlar. |
| private / private(set) | Erişim sınırı / sadece setter sınırı | items dışarıdan okunur, doğrudan yazılamaz. |
| String? | Değer veya nil | storageError, hata yokken nil. |
| if let / guard let | Optional’ı güvenli açma | Hata metni ve görev indeksi. |
| ?? | nil için varsayılan değer | Özel URL yoksa Application Support. |
| $newTitle | Property wrapper’ın yansıtılan değeri | TextField’a Binding<String> verir. |
| $0, $1 | Closure’ın kısa parametre adları | filter ve sorted içindeki öğeler. |
| \.isCompleted | Bir özelliğe key path | Tamamlananları filtrelemek. |
| &updated / inout | Değiştirilebilir argüman aktarımı | Ortak update closure’ı. |
| some View | Gizli somut dönüş tipi | Görünüm bileşenlerinin dönüşü. |
| @Test / #expect | Özellik işareti / test makrosu | Swift Testing testleri. |

$ sözdiziminin iki farklı rolüne özellikle dikkat et: $newTitle bir binding elde eder; $0 closure’ın ilk argümanına verilen kısa addır. Benzer görünmeleri aynı mekanizma oldukları anlamına gelmez. String içindeki \(değer) ise string interpolation’dır; değeri metne dönüştürüp birleştirir.

## 5.2. Durumun sahibi kim?

| Mekanizma | Bu projede nerede? | Görevi |
| --- | --- | --- |
| @StateObject | ios_testApp.store | Gözlemlenebilir deponun yaşamını sahiplenir. |
| .environmentObject | App ve Preview | Aynı nesneyi alt görünüm ağacına sağlar. |
| @EnvironmentObject | ContentView.store | Sağlanan nesneyi alır ve değişikliklerini izler. |
| @Published | items, storageError | Nesnenin veri değişikliğini gözlemcilere bildirir. |
| @State | filter, search, taslaklar | Görünüme ait geçici değer durumunu saklar. |
| @FocusState | composerFocused | Durumu klavye odağıyla bağlar. |
| Binding | $search, $editedTitle | Bir değere iki yönlü okuma-yazma bağlantısı sağlar. |

@StateObject seçimi, her body değerlendirmesinde yeni TaskStore üretme hatasını önler. @EnvironmentObject ise nesnenin sahibi değildir; nesne daha yukarıda sağlanmalıdır. Kaynak [3] sahiplik modelini, kaynak [4] model verisinin görünüm ağacında paylaşımını açıklar. Proje mevcut ObservableObject yaklaşımını kullanır; bu rehber kodu yeni bir gözlem modeline dönüştürmez.

Hesaplanan completedCount ve visibleItems ayrı @State değildir. Bunlar asıl veriden türetilir. Aynı bilginin hem items hem filteredItems gibi iki bağımsız yerde tutulması, birini güncelleyip diğerini unutma riskini artırır. Mevcut tasarım küçük listelerde anlaşılırdır; görünür liste her kullanımda yeniden hesaplanabildiği için büyüyen veriyle maliyeti ölçmek gerekir.

## 5.3. Closure ve fonksiyon değeri

Closure, argüman olarak taşınabilen kod bloğudur. TaskStore.update bir işlem alır: eklemede insert, silmede removeAll, düzenlemede başlık ataması yapılır. Kayıt kodu ortak kalır. Swift closure kuralları için kaynak [5]’e bak.

```swift
update { items in
    // items üzerinde istenen değişiklik
}
```

inout [TodoItem], closure’ın bu dizi değişkenini değiştirebilmesini sağlar. update içindeki mutation(&updated) çağrısında & gereklidir. Bu bir ağ isteği, async iş veya sonradan çağrılan kuyruk değildir; mevcut closure senkron çalışır. Dış update ile iç closure’ın return kapsamlarının farklı olması önemlidir: indeksi bulamayan closure’dan return etmek, dış fonksiyonun devamını otomatik durdurmaz.

## 5.4. MainActor ne sağlar, ne sağlamaz?

TaskStore’un @MainActor olması, durumuna erişimi ana aktör bağlamında toplar. SwiftUI’yla ilişkili değişikliklerin tutarlı bağlamda yapılmasına yardımcı olur. Buna karşın dosya I/O’su otomatik olarak arka plana taşınmaz. Data(contentsOf:) ve write çağrıları burada senkrondur. Küçük JSON için basitlik sağlar; büyük dosyada kullanıcı arayüzü takılabilir. Kaynak [6], MainActor ve actor izolasyonunun temelini açıklar.

# 6. Kalıcı veri, hatalar ve tasarım kararları

## 6.1. Kayıt işleminin sırası

```text
items (son başarılı durum)
       |
       v
updated = items  -> mutation(&updated)
       |
       v
JSONEncoder -> atomik dosya yazımı
       |
       +-- başarı --> items = updated --> arayüz güncellemesi
       |
       +-- hata ----> storageError     --> eski items korunur
```

Bu sıra, ekranda başarılı görünmüş ama diske yazılmamış bir değişikliği normal başarı yolu olarak göstermemek için seçilmiştir. Önce items değişseydi ve yazma başarısız olsaydı, geri alma veya tutarsızlığı yönetme gereksinimi doğardı. Buradaki bedel, dosya yazmasının UI güncellemesinden önce senkron tamamlanmasıdır.

.atomic seçeneği bir yardımcı dosyaya yazıp hedefi değiştirme yaklaşımıyla yarım dosya riskini azaltır. “Atomik” demek otomatik yedek, şifreleme, her koşulda veri kurtarma veya çok süreçli veritabanı işlemi demek değildir. İlgili Foundation seçeneği kaynak [7]’dedir.

## 6.2. JSON ve model uyumu

Codable, TodoItem’ın saklanan alanlarından JSON kodlama ve çözümleme üretir. Date ve UUID de bu mekanizmaya katılır. Varsayılan JSONEncoder tarih stratejisi, insanın okuyacağı ISO 8601 metni olarak ayrıca ayarlanmamıştır; tarih çıktısını özel format sanmamak gerekir. id ve createdAt için başlangıç değeri bulunması, eski JSON’da eksik zorunlu alanların otomatik olarak doldurulacağı anlamına gelmez.

İleride alanlar eklenirse dosya formatı uyumluluğu düşünülmelidir: optional alan, özel init(from:), varsayılan çözümleme veya şema geçişi seçenekleri değerlendirilebilir. Mevcut uygulamada şema sürümü ve veri göçü mekanizması yoktur. createdAt şu anda saklanır ama ekranda ve sıralamada kullanılmaz.

## 6.3. Mevcut davranışın sınırları

- Okuma hatası, yeni değişiklikleri durdurur ve mevcut dosyanın üzerine yazılmasını önler. Bozuk JSON’u otomatik düzeltmez.
- Yazma hatası da storageError alanını doldurur; update başındaki guard sonraki değişiklikleri engeller. Arayüzde bir “yeniden dene ve hatayı temizle” akışı yoktur.
- Silme doğrudan yapılır. destructive rolü onay penceresi veya undo sağlamaz.
- Hata mesajları, gerçek Error ayrıntılarını kullanıcıya veya günlüğe taşımıyor. Sorun tanılama sınırlıdır.
- Görevlerin yerel saklanması, dosyanın şifrelenmiş olduğu anlamına gelmez. Uygulama seviyesinde şifreleme uygulanmaz.
- Date.now kullanan başlık bir saat/takvim zamanlayıcısı değildir. Güneş simgesi hava durumu göstergesi değildir.
- UI testleri gerçek kullanıcı görev dosyasından ayrılmış bir launch argümanı kullanmıyor. Etkileşim testleri genişletilmeden önce yalıtılmış test deposu sağlanmalıdır.

Bunlar bu rehberde düzeltilen hatalar veya eklenen özellikler değildir; mevcut kodu doğru anlamak için kaydedilmiş gözlemlerdir. Ürün gereksinimi ve ölçüm olmadan her küçük uygulamaya veritabanı, soyutlama katmanları veya ağ sistemi eklemek gerekmez.

# 7. Kaynak dosyaları satır satır

Sonraki altı bölümde her fiziksel kaynak satırı gösterilir. Numaralar ilgili dosyanın kendi satır numaralarıdır. Uzun kod satırları PDF’de birkaç görsel satıra sarılabilir; bu durum kaynak numarasını değiştirmez. Boş satırların düzenleme amacı, kapanışların ise hangi kapsamı bitirdiği belirtilir. Aynı satırda birden fazla modifier veya ifade varsa birlikte açıklanır.

Satır açıklamalarında “kapsam” sözcüğü, süslü parantezle açılan fonksiyon, closure, tip veya kontrol bloğunu ifade eder. Kapanış açıklamasındaki başlangıç numarası, ilgili dosyanın açılış satırına geri dönmeyi kolaylaştırır.
