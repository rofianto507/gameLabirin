# Context Proyek: Game Labirin Android TV

> Ringkasan untuk melanjutkan pengembangan di VS Code + Claude. Baca file ini dulu sebelum mengubah kode.
> Bahasa komunikasi: Indonesia. Terakhir diperbarui: 13 Okt 2026 (kode awal v0.1).

## 1. Ringkasan
Game petualangan labirin 2D untuk **Android TV di rumah**, dimainkan **dua anak secara bergantian**.
Dipasang pribadi (sideload APK), **bukan** untuk Play Store, jadi tanpa iklan/IAP/kebijakan Families.

- **Pemain:** Xhaka (kakak, 8 th, bola biru `#1E88E5`) dan Razkhan (adik, 5 th, bola oranye `#FF8F00`).
- **Target usia:** 5-10 tahun. Bahasa: **Indonesia saja**.
- **Platform/tool:** Flutter (Dart), tanpa package game engine di v0.1 (CustomPainter + Ticker). `shared_preferences` untuk menyimpan bintang.
- **Kontrol:** D-pad remote TV dan gamepad (D-pad = tombol panah, tombol A = OK). Tersedia 1 gamepad + 1 remote. Versi awal **bergantian**, bukan bersamaan.
- **Sudut pandang:** 2D top-down, karakter bola dulu (nanti gambar dari foto anak).

## 2. Nama game (usulan, belum final)
1. **Kuna dan Bintang Jatuh** (dipakai sementara di kode)
2. Labirin Kuna
3. Petualangan Kuna si Kunang-kunang
4. Kuna Penjaga Cahaya
5. Bintang Jatuh di Labirin
6. Kuna dan Tiga Dunia Cahaya
7. Cahaya di Ujung Labirin
8. Pahlawan Cahaya

Jika nama diganti: ubah `title` di `lib/main.dart`, teks judul di `lib/ui/profile_screen.dart`, dan label aplikasi di `android/app/src/main/AndroidManifest.xml` (`android:label`).

## 3. Cerita
Bintang besar di langit pecah; kepingannya jatuh ke 3 dunia. **Kuna** (kunang-kunang, penjaga cahaya malam) meminta pemain
menolong penghuni tiap dunia dan mengumpulkan 3 kepingan. Di akhir, bintang utuh kembali ke langit dan **nama kedua anak muncul sebagai bintang**.

## 4. Prinsip desain (usia 5-10)
- **Tidak ada game over / hukuman.** Gagal = coba lagi atau terpental lucu.
- Minim teks, banyak ikon/animasi/suara. Satu tombol aksi (arah + OK).
- Hadiah sering (bintang, koleksi), tanpa skor perbandingan.
- Kuna memberi petunjuk bertahap kalau anak buntu (jejak cahaya setelah diam 8 detik).
- Suasana "penasaran", bukan menakutkan. Tanpa musuh yang mengejar.
- UI TV: teks besar, fokus jelas (tombol membesar + bingkai putih), margin aman ~5% (padding 48/27).

## 5. Dunia (v1 = 3 dunia x 5 stage)
| Dunia | Suasana | Mekanik khas (rencana) | Item | Status kode |
|---|---|---|---|---|
| Hutan Pelangi | cerah, ceria | semak dibuka dengan buah | buah | tema+item saja |
| Gua Kristal | tenang, berkilau, agak gelap | kristal menerangi, cahaya dipantulkan buka pintu | kristal | tema+item saja |
| Desa di Awan | lembut, melayang | lantai awan hilang-muncul | bulu burung | tema+item saja |

Stage 1-2 pengenalan, 3-4 lebih besar, 5 penutup (momen spesial). Selesai dunia = kepingan bintang.

## 6. Status kode v0.1 (sudah ada)
- Menu pilih profil -> pilih dunia/stage (semua terbuka) -> game.
- Labirin acak tiap main (recursive backtracker + jalan pintas/loop), awal (0,0), pintu keluar di sel terjauh (BFS).
- Item wajib (2,2,3,3,4 per stage) tersebar merata; pintu terkunci sampai semua terkumpul.
- 2 bintang bonus tersembunyi (utamakan jalan buntu); bintang hadiah = 1 + bonus (maks 3). Tersimpan per profil di `shared_preferences`.
- Kuna: kunang-kunang yang melayang di dekat pemain, balon teks, **jejak petunjuk** ke target berikutnya setelah diam 8 detik.
- Anak 5 tahun (`PlayerProfile.easy`) mendapat labirin lebih kecil dan lebih banyak jalan pintas.
- Gerak per-sel dengan animasi halus; tahan tombol arah = jalan terus.
- Layar menang: bintang, tombol Lanjut / Main lagi / Menu (fokus D-pad).
- **Belum ada:** suara/musik, mekanik khas dunia, gambar karakter foto, mode berdua, cerita penutup, tombol jeda.

## 7. Struktur folder
```
context.md                  <- file ini
setup.bat, tv_patch.ps1     <- siapkan folder android + patch manifest TV (sekali jalan)
pubspec.yaml
docs/
  skrip_suara_kuna.md       <- skrip rekaman suara Mama (kode A01..J02)
  panduan_desain_karakter.md
lib/
  main.dart                 <- app, orientasi landscape, immersive, tombol A gamepad = OK
  data/models.dart          <- PlayerProfile, GameWorld (warna/tema), ukuran labirin per stage
  data/progress.dart        <- simpan bintang (shared_preferences)
  maze/maze.dart            <- MazeData, MazeGenerator, BFS findPath
  game/game_screen.dart     <- logika stage: input, gerak, item, hint, menang
  game/maze_painter.dart    <- menggambar labirin, bola, item, pintu, Kuna
  ui/profile_screen.dart    <- pilih Xhaka/Razkhan
  ui/stage_select_screen.dart
  ui/widgets.dart           <- TvButton (fokus D-pad), PlayerBall, StarRow
```

## 8. Cara menjalankan
Kode ditulis tanpa bisa dikompilasi di sini, jadi **kemungkinan ada galat kecil saat pertama build**; perbaiki bersama Claude.

1. Pastikan Flutter terpasang. Di folder proyek jalankan `setup.bat` (membuat folder `android` tanpa menimpa `lib/`, menambah pengaturan Android TV ke manifest, lalu `flutter pub get`).
2. Uji cepat tanpa TV: `flutter run -d windows` atau `-d chrome` (panah keyboard = D-pad; Enter = OK). Catatan: platform Windows/web perlu `flutter create . --platforms=windows` bila ingin dipakai; atau pakai emulator Android TV.
3. Ke TV: aktifkan Developer options + ADB debugging di TV, `adb connect <ip-tv>:5555`, lalu `flutter run -d <ip-tv>:5555` atau `flutter build apk --release` dan `adb install -r build\app\outputs\flutter-apk\app-release.apk`.
4. Agar muncul di launcher TV, tambahkan banner 320x180 (`android:banner` di tag `<application>`); tanpa banner kadang hanya muncul di menu "Apps/Settings".

## 9. Peta jalan (urutan saran)
1. Kompilasi dan uji di TV; setel kecepatan (`_speed`), ukuran labirin, kontras warna.
2. Tombol jeda (gamepad Start/menu) + konfirmasi keluar.
3. Suara: efek (ambil item, buka pintu, boing) dan rekaman Kuna sesuai `docs/skrip_suara_kuna.md`
   (paket `audioplayers`; nama berkas `assets/audio/A01.m4a`; nama anak disambung dari berkas terpisah).
   Titik pemanggilan sudah ditandai komentar `// D02`, `// E01` dst. di `game_screen.dart` (`_kunaSay`).
4. Mekanik khas dunia: semak/buah (Hutan), kristal dan cermin cahaya + fog of war ringan (Gua), awan hilang-muncul (Desa).
5. Ganti bola dengan sprite karakter dari foto (lihat `docs/panduan_desain_karakter.md`); animasi jalan lewat kode.
6. Cerita: intro Kuna, kepingan bintang per dunia, penutup dengan nama anak di langit.
7. Rintangan ramah anak: makhluk lucu berpatroli (terpental "boing", mundur beberapa langkah).
8. Mode berdua bersamaan (kamera satu layar, kerja sama; gamepad + remote), baru setelah mode bergantian mantap.

## 10. Keputusan penting (jangan dilanggar tanpa diskusi)
- Tidak ada game over, timer menekan, atau musuh yang mengejar.
- Co-op nantinya **kerja sama**, bukan bersaing.
- Semua stage terbuka (tidak ada penguncian) agar tidak ada rebutan/frustrasi.
- Tanpa iklan, tanpa internet, tanpa chat.
- Aset suara: rekaman Mama. Aset gambar: dibuat sendiri dari foto anak (bola dulu).
- Bintang hadiah tidak dipengaruhi kecepatan atau pemakaian petunjuk.

## 11. Catatan teknis
- Input: `Focus.onKeyEvent` di `GameScreen` membaca panah/WASD (D-pad gamepad Android dikirim sebagai tombol panah). Daftar tombol yang ditahan (`_held`) menentukan arah langkah berikutnya.
- Menu memakai fokus bawaan Flutter (`InkWell`); `TvButton` hanya menambah efek fokus. Setelah menang, fokus dipindah manual ke tombol "Lanjut" (`_nextFocus`).
- `MazePainter.shouldRepaint` selalu `true` (animasi tiap frame); cukup ringan untuk labirin maks 16x9.
- Ukuran labirin: lihat `mazeCols/mazeRows` di `models.dart`. Kolom 6+2*stage, baris 4+stage (anak kecil -2 / -1).
- `withOpacity` mungkin memberi peringatan deprecated di Flutter terbaru; ganti ke `withValues(alpha: ...)` bila perlu.
