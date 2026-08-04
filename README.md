# Meowtrack - AR Cat Tracking & Care System 🐾

Aplikasi mobile Flutter yang menggabungkan Augmented Reality (AR) untuk penjagaan kucing, pengesanan GPS, dan pemantauan kesihatan dengan integrasi kecerdasan buatan (Gemini AI).

---

## 🛠️ Panduan Untuk Pembangun (Developers Guide)

Kod sumber ini disediakan sebagai versi **"Clean Source Code"**. Semua kunci API dan fail konfigurasi sensitif telah dibuang untuk tujuan keselamatan. Untuk menjalankan projek ini secara lokal, sila ikuti langkah-langkah berikut:

### 1. Prasyarat
- [Flutter SDK](https://docs.flutter.dev/get-started/install) versi terbaru.
- Akaun [Firebase](https://console.firebase.google.com/).
- Akaun [Google AI Studio](https://aistudio.google.com/) (Untuk Gemini AI).
- Akaun [Google Cloud Console](https://console.cloud.google.com/) (Untuk Maps API).

### 2. Konfigurasi Firebase
Oleh kerana fail `google-services.json` tidak disertakan, anda perlu:
1. Cipta projek baru di Firebase.
2. Daftar aplikasi Android (`com.example.meow_track`).
3. Muat turun fail `google-services.json` dan letakkan di dalam folder `android/app/`.

### 3. Konfigurasi Kunci API (Environment Variables)
Aplikasi ini menggunakan pembolehubah persekitaran untuk menyimpan kunci API.
1. Salin fail `.env.example` dan namakannya sebagai `.env`.
2. Masukkan kunci API anda yang sah di dalam fail tersebut:
   ```env
   GEMINI_API_KEY=KUNCI_GEMINI_ANDA
   GOOGLE_MAPS_API_KEY=KUNCI_GOOGLE_MAPS_ANDA
   ```

### 4. Menjalankan Projek
```bash
flutter pub get
flutter run
```

---

## 🚀 Ciri-Ciri Utama
- **AI Paws (Gemini AI)**: Pembantu pakar kucing interaktif dengan sokongan **Voice (Speech-to-Text)** dan **Vision (Image Analysis)**.
- **Digital Health Passport**: Rekod perubatan digital yang disahkan oleh Admin/Vet.
- **Kibble Tracker**: Imbas label makanan menggunakan AI untuk mengira kalori harian.
- **GPS Tracking & Geofencing**: Pemantauan lokasi kucing secara masa-nyata.
- **Digital Pet Tag**: Jana kod QR unik untuk diletakkan pada kolar kucing.
- **Dynamic Rank System**: Tingkatkan pangkat "Pawrent" anda melalui penglibatan dalam app.

## 🛡️ Keselamatan & Privasi
- **Firebase App Check**: Dilengkapi dengan *Play Integrity* untuk menghalang akses tidak sah.
- **Code Obfuscation**: Menggunakan R8 dan ProGuard untuk melindungi logik aplikasi.
- **Git History Clean**: Sejarah repository telah dibersihkan sepenuhnya daripada kebocoran data.

---

## 📦 Muat Turun APK (Demo)
Anda boleh memuat turun fail APK demo di bahagian [**Releases**](https://github.com/ipanznx1/Meowtrack-App/releases). 
*Nota: Versi APK demo ini tidak disertakan dengan kunci API aktif (fungsi AI & Maps mungkin tidak berfungsi).*

---

**Happy Tracking! 🐱✨**
*Developed with ❤️ for cat lovers.*
