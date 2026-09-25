# Eğitim rehberinin kaynakları

Ana çıktı: [Odak — Satır Satır Geliştirici Rehberi](../odak-gelistirici-rehberi.pdf).
Metin sürümü: [Markdown](../odak-gelistirici-rehberi.md).

- `handbook.md`: Mimari, araçlar ve SwiftUI temelleri.
- `annotations.txt`: Dosya adı ve satır numarasıyla eşlenmiş özgün açıklamalar.
- `appendix.md`: Proje ayarları, test kapsamı, alıştırmalar ve kaynaklar.
- `source_snapshot.json`: Açıklamaların dayandığı kaynak dosyaların SHA-256 özetleri.
- `build_guide.py`: PDF ve birleşik Markdown üretimi; eksik açıklama veya değişmiş kaynakta durur.
- `coverage.json`: Üretim kapsamı: 6 Swift dosyası, 514 fiziksel satır.
- `verify_guide.py`: PDF metin, satır kapsamı, font ve taşma kontrolü.

## Yeniden üretme

macOS üzerinde Python 3.10 veya üzeri ile çalıştırılabilir. Betik, `/System/Library/Fonts/Supplemental` altındaki Arial, Courier New ve Arial Unicode fontlarını kullanır. Farklı sistemde `FONT_DIR` ve font eşlemelerini uyarlayın.

```sh
python3 -m venv /tmp/odak-pdf-env
/tmp/odak-pdf-env/bin/pip install -r docs/education/requirements.txt
/tmp/odak-pdf-env/bin/python docs/education/build_guide.py
/tmp/odak-pdf-env/bin/python docs/education/verify_guide.py
```

Kaynak kod değiştiyse önce satır açıklamalarını ve rehberdeki davranış anlatımını gözden geçirin. Ardından `source_snapshot.json` içindeki özetleri bilinçli biçimde güncelleyin. Toplam satır sayısı değişmişse metindeki kapsam bilgilerini ve üretim kontrolünü de güncelleyin. Yalnızca özeti değiştirip eski açıklamaları kullanmak doğru bir güncelleme değildir.

Bu araçlar yalnızca dokümantasyon üretir; Swift uygulamasına bağımlılık eklemez ve uygulama testlerini çalıştırmaz.
