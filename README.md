# Kuna dan Bintang Jatuh 🌟

Game petualangan labirin 2D untuk **Android TV**, dibuat untuk dimainkan di rumah oleh dua
anak secara bergantian. Dipasang pribadi lewat sideload APK — **bukan** untuk Play Store,
jadi tanpa iklan, tanpa IAP, dan tanpa koneksi internet.

> Nama "Kuna dan Bintang Jatuh" masih sementara dan bisa berubah seiring pengembangan.

## Cerita singkat

Bintang besar di langit pecah dan kepingannya jatuh ke tiga dunia. **Kuna**, kunang-kunang
penjaga cahaya malam, mengajak pemain menolong penghuni tiap dunia dan mengumpulkan kembali
kepingan bintang itu.

## Fitur saat ini

- Pilih profil pemain (bergantian), lalu pilih dunia & stage. Stage harus diselesaikan
  berurutan — stage/dunia berikutnya terkunci (ikon gembok) sampai yang sebelumnya tamat —
  tapi tanpa hukuman kalau gagal di tengah jalan (bisa coba lagi kapan saja).
- Labirin dibuat acak setiap main (recursive backtracker + beberapa jalan pintas), dengan
  item wajib yang harus dikumpulkan sebelum pintu keluar terbuka, dan bintang bonus
  tersembunyi di jalan buntu.
- **Kuna** menemani pemain: memberi jejak petunjuk otomatis kalau anak diam/bingung lama,
  dan punya dialog singkat di sepanjang permainan.
- Tingkat kesulitan otomatis menyesuaikan usia profil (labirin lebih kecil & lebih banyak
  jalan pintas untuk anak yang lebih kecil).
- **Tombol jeda**: tombol Back di remote TV / Escape / Start di gamepad membuka overlay
  jeda (bukan langsung keluar), dengan pilihan **Lanjut** atau **Kembali ke menu**.
- Navigasi sepenuhnya lewat D-pad/gamepad (tombol panah + satu tombol OK), sesuai dengan
  kontrol remote TV — tidak memerlukan kursor/sentuhan.
- UI ramah anak: font bulat **Fredoka**, latar gradasi malam yang bergerak pelan, dan
  karakter yang "hidup" (berkedip, melirik, senyum berubah-ubah saat idle).
- Progres bintang tersimpan per profil secara lokal (`shared_preferences`).
- Musik latar dan efek suara (pilih/klik, dapat item, dapat bintang, menang, stage
  terkunci, terpental) — efek suaranya disintesis sendiri, bukan aset pihak ketiga (lihat
  `tool/generate_sfx.dart`).
- **Kanapi** (penjaga kecil berbentuk bola api, beberapa per stage) berpatroli bolak-balik
  tanpa pernah mengejar, dan **Holobon** (boss berbentuk bola bulu hitam, satu per dunia di
  stage penutup) berpatroli dekat pintu keluar dan mengejar terbatas beberapa sel kalau
  didekati. Keduanya cuma bikin terpental ringan kalau tersentuh — tanpa hukuman, bintang/
  progres tidak berkurang.

### Belum ada (rencana berikutnya)

- Rekaman suara Kuna (skrip sudah disiapkan, lihat `docs/skrip_suara_kuna.md`).
- Mekanik khas tiap dunia (semak/telur, kristal & cahaya, awan hilang-muncul).
- Karakter dari foto asli (saat ini masih karakter bola berwarna, lihat
  `docs/panduan_desain_karakter.md`).
- Mode bermain berdua secara bersamaan (saat ini bergantian).
- Cerita penutup setelah tiga dunia selesai.

## Kontrol

| Tombol | Fungsi |
|---|---|
| D-pad / panah / WASD | Gerak karakter, pilih menu |
| OK / Enter / tombol A gamepad | Pilih / konfirmasi |
| Back (remote) / Escape / Start (gamepad) | Jeda permainan + konfirmasi keluar |

## Teknologi

- [Flutter](https://flutter.dev) (Dart) — tanpa paket game engine, rendering labirin &
  karakter memakai `CustomPainter` + `Ticker` langsung.
- `shared_preferences` untuk menyimpan bintang per profil.
- Target utama: **Android TV** (landscape, mode immersive, dukungan leanback launcher).

## Struktur proyek

```
lib/
  main.dart                 - entry point, orientasi landscape, shortcut tombol OK gamepad
  data/
    models.dart              - profil pemain, data dunia, ukuran labirin per stage
    progress.dart            - simpan/baca bintang (shared_preferences)
  maze/
    maze.dart                 - generator labirin & pencarian jalur (BFS)
  game/
    game_screen.dart          - logika satu sesi permainan (gerak, item, jeda, menang)
    maze_painter.dart         - gambar labirin, karakter, item, Kuna
  ui/
    profile_screen.dart       - pilih profil pemain
    stage_select_screen.dart  - pilih dunia & stage
    widgets.dart               - komponen UI bersama (tombol D-pad, latar, karakter animasi)
docs/
  skrip_suara_kuna.md         - skrip rekaman suara Kuna
  panduan_desain_karakter.md  - panduan desain karakter dari foto
assets/
  fonts/                      - font Fredoka (lisensi OFL)
  icon/                        - gambar sumber ikon aplikasi
  audio/                       - musik latar & efek suara
test/                          - widget test (navigasi D-pad, fitur jeda)
tool/                          - skrip bantu dev (generate ikon/efek suara, screenshot beberapa resolusi TV)
```

## Mulai menjalankan

Prasyarat: [Flutter SDK](https://docs.flutter.dev/get-started/install) sudah terpasang.

1. Siapkan folder Android (sekali saja):
   ```
   setup.bat
   ```
   Skrip ini membuat folder `android/` tanpa menimpa kode di `lib/`, menambahkan pengaturan
   Android TV ke manifest, lalu menjalankan `flutter pub get`.
2. Uji cepat tanpa TV (opsional, untuk pengembangan):
   ```
   flutter run -d chrome
   ```
   atau emulator Android TV. Panah keyboard berfungsi sebagai D-pad, Enter sebagai OK.
3. Jalankan di TV sungguhan: aktifkan **Developer options** + **ADB debugging** di TV, lalu
   ```
   adb connect <ip-tv>:5555
   flutter run -d <ip-tv>:5555
   ```
4. Build APK rilis untuk sideload:
   ```
   flutter build apk --release
   adb install -r build\app\outputs\flutter-apk\app-release.apk
   ```

## Testing & alat bantu dev

```
flutter analyze        # cek statis
flutter test            # widget test (navigasi D-pad, fitur jeda)
```

Folder `tool/` berisi skrip pengembangan sekali-jalan, bukan bagian dari aplikasi:

- `tool/generate_icon.dart` — merender ulang ikon aplikasi dari karakter Kuna (jalankan
  lewat `flutter test tool/generate_icon.dart`).
- `tool/screenshot_screens.dart` — merender layar ke PNG di beberapa resolusi TV (720p,
  1366×768, 1080p) untuk memeriksa tata letak tanpa perlu perangkat TV asli (jalankan
  lewat `flutter test tool/screenshot_screens.dart`).
- `tool/generate_sfx.dart` — mensintesis efek suara (nada sinus) ke `assets/audio/sfx_*.wav`,
  tanpa dependensi aset pihak ketiga (jalankan lewat `dart run tool/generate_sfx.dart`).

## Kredit & lisensi

- Font **Fredoka** dari [Google Fonts](https://fonts.google.com/specimen/Fredoka), dipakai
  di bawah lisensi [SIL Open Font License](assets/fonts/OFL.txt).
- Desain karakter, labirin, dan ilustrasi dibuat sendiri. Efek suara juga disintesis
  sendiri (lihat `tool/generate_sfx.dart`), jadi bebas lisensi.
- Musik latar (`assets/audio/bgm.mp3`) dipilih sendiri oleh pembuat proyek; pastikan
  lisensinya sesuai sebelum dipakai di luar lingkup pribadi.
- Proyek ini untuk penggunaan pribadi/keluarga, bukan untuk distribusi publik atau Play
  Store.
