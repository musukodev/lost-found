# Lost & Found Sekolah

Aplikasi Flutter untuk ATS Praktikum Pemrograman Perangkat Bergerak. Fokus frontend, seluruh data awal adalah dummy dan tidak terhubung server. Identitas masuk demo bukan autentikasi akun sekolah.

## Jalankan

Prasyarat: Flutter stable dengan Dart >=3.13.4. Versi yang digunakan saat implementasi: Flutter 3.47.5, Dart 3.13.4.

```sh
cd /home/musuko/Projects/ats-ppb/aplikasi
flutter pub get
flutter run
```

Preview web:

```sh
flutter run -d chrome
```

Build:

```sh
flutter build apk --debug
flutter build web --no-web-resources-cdn
```

APK demo: `build/app/outputs/flutter-apk/app-debug.apk`. Ini build debug untuk pengujian lokal, bukan rilis Play Store.

## Fitur dan halaman

Sembilan screen: pembuka, masuk demo, beranda, jelajah, detail, buat laporan, laporan saya, tersimpan, pengaturan.

- Cari nama/ciri/lokasi, filter Hilang/Ditemukan dan kategori.
- Tambah laporan dengan validasi nama barang, lokasi, tanggal, dan ciri-ciri.
- Draf otomatis dipulihkan saat berpindah halaman dan aplikasi dibuka kembali.
- Simpan/hapus simpanan barang dari detail.
- Tandai selesai hanya untuk laporan dengan identitas demo aktif.
- Tema terang/gelap, keluar demo, dan pemulihan data demo dengan konfirmasi.

Status item, sesi demo, draf, simpanan, dan tema disimpan menggunakan shared_preferences. Query dan tab berada di AppStore selama proses aktif. Pindah halaman dan rotasi tidak menginisialisasi ulang AppStore. Query/tab tidak dipulihkan setelah proses dihentikan.

## Pengujian

```sh
flutter analyze
flutter test --concurrency=1
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart -d emulator-5554
```

Integration test menghapus data aplikasi demo pada emulator yang ditargetkan, menjalankan alur pengguna, memeriksa rotasi, dan menulis screenshot ke `../bukti/`. Gunakan emulator khusus pengujian.

## Struktur

- `lib/main.dart`: tema, navigasi, sembilan screen, komponen UI.
- `lib/store.dart`: model, dummy data, ChangeNotifier, validasi, penyimpanan lokal.
- `test/`: pengujian state, validasi, alur widget, layout pada beberapa ukuran dan tema.
- `integration_test/app_test.dart`: alur Android dan bukti screenshot.
- `test_driver/integration_test.dart`: penulisan screenshot integration test.
- `assets/fonts/`: font Manrope lokal dan lisensi OFL.

## Batasan

Ini simulasi frontend offline. Tidak ada backend, unggah foto, verifikasi kepemilikan sungguhan, notifikasi, chat, atau pengiriman pesan. Cara mengambil barang hanya menampilkan panduan. Identitas nama/kelas lokal tidak menjamin otorisasi aman; cocok untuk data dummy sesuai soal. Data di shared_preferences bukan penyimpanan data sensitif. Pemulihan data demo menghapus laporan lokal buatan pengguna, draf, dan simpanan setelah konfirmasi.

Logo launcher bawaan Flutter adalah placeholder dari scaffold; identitas aplikasi di dalam UI menggunakan nama teks.

Laporan diisi pada DOCX yang sudah ada di direktori induk. Tidak ada file DOCX laporan baru. Ketentuan vlog, deadline, unggah e-learning/arsip, dan publikasi/penyerahan source code dikecualikan sesuai instruksi pengguna.
