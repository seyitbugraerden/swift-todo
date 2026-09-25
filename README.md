# Odak

SwiftUI ile geliştirilmiş, Türkçe arayüzlü bir macOS yapılacaklar uygulaması.

## Çalıştırma

1. Tam Xcode uygulamasını kurun (yalnızca Command Line Tools yeterli değildir).
2. `ios_test.xcodeproj` dosyasını Xcode ile açın.
3. `ios_test` şemasını ve `My Mac` hedefini seçin.
4. **⌘R** ile çalıştırın. macOS 14 veya üzeri gerekir.

`ContentView.swift` dosyası için **Editor → Canvas** üzerinden SwiftUI önizlemesi açılabilir.

## Özellikler

- Görev ekleme, düzenleme, tamamlama ve silme
- Önemli görevler ve tamamlananlar için filtreler
- Görev metninde arama
- Tamamlanma yüzdesi
- Sistemle uyumlu açık/koyu görünüm
- Yeni görev alanına geçmek için **⌘N**, eklemek için **Return**
- Yerel ve atomik JSON kaydı: `~/Library/Application Support/Odak/tasks.json`

Görevler buluta gönderilmez. Kayıt dosyası okunamazsa mevcut veriyi korumak için değişiklikler engellenir; hata arayüzde gösterilir.

## Doğrulama

Xcode’da **⌘U** ile testleri çalıştırabilirsiniz. Model testleri; boş görevlerin reddedilmesini, görevlerin yeniden yüklenmesini, düzenleme/tamamlama/silme işlemlerini ve bozuk kayıtların korunmasını kapsar.
