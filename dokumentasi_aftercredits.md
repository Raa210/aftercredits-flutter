# Dokumentasi Laporan Proyek — AfterCredits

> **Aplikasi Komunitas Film Mobile (Flutter)**
> Versi 1.0.0 · Tahun 2026

---

## Daftar Isi

1. [Executive Summary](#1-executive-summary)
2. [Arsitektur & Struktur Teknis](#2-arsitektur--struktur-teknis)
3. [Implementasi Aplikasi](#3-implementasi-aplikasi)
4. [Kesimpulan](#4-kesimpulan)

---

## 1. Executive Summary

### 1.1 Latar Belakang

Di era digital saat ini, konsumsi konten film telah mengalami lonjakan signifikan, didorong oleh ekspansi platform streaming seperti Netflix, Disney+, dan Prime Video. Namun, pengalaman menonton film sebagian besar masih bersifat individual dan pasif. Pengguna tidak memiliki ruang terpadu untuk mencatat tontonan mereka, berbagi pendapat, dan berinteraksi dengan sesama penikmat film dalam satu ekosistem yang kohesif.

Platform seperti **Letterboxd** (yang berbasis web) menunjukkan bahwa ada pasar yang besar untuk komunitas film yang terstruktur dan bersosial. Akan tetapi, penetrasi platform tersebut di kalangan pengguna berbahasa Indonesia masih terbatas, baik dari segi lokalisasi antarmuka maupun konteks budaya lokal.

### 1.2 Permasalahan

Berdasarkan latar belakang di atas, terdapat beberapa permasalahan utama yang diidentifikasi:

1. **Tidak adanya platform komunitas film mobile** dalam Bahasa Indonesia yang menyatukan fungsi pencarian film, manajemen tontonan, ulasan, dan diskusi dalam satu aplikasi.
2. **Fragmentasi pengalaman pengguna** — pengguna harus berpindah antara berbagai aplikasi untuk mencari informasi film (TMDB, IMDb), menyimpan daftar tontonan (spreadsheet pribadi), dan berdiskusi (grup chat).
3. **Kurangnya personalisasi berbasis selera** — tidak ada rekomendasi film yang disesuaikan dengan genre favorit dan riwayat tontonan pengguna secara personal.
4. **Minimnya fitur sosial** — belum ada mekanisme untuk mengikuti aktivitas teman dalam menonton, memberikan ulasan, atau membuat diskusi film.

### 1.3 Tujuan

Proyek ini bertujuan untuk:

1. Membangun aplikasi **komunitas film mobile** berbasis Flutter yang terintegrasi penuh dengan database film TMDB.
2. Menyediakan fitur **manajemen tontonan pribadi** (watched list, watchlist) dengan sinkronisasi cloud via Supabase.
3. Memfasilitasi **interaksi sosial** antarpengguna melalui sistem follow, ulasan, komentar, dan diskusi.
4. Menampilkan **feed aktivitas teman** (Following Activity) sehingga pengguna dapat mengikuti aktivitas sinematik orang-orang yang mereka ikuti.
5. Menyajikan **rekomendasi film personal** berdasarkan genre favorit dan riwayat tontonan.

### 1.4 Solusi dan Metode

**AfterCredits** dikembangkan sebagai aplikasi mobile lintas platform menggunakan **Flutter** dengan arsitektur berbasis layanan (Service-based Architecture). Solusi yang diberikan mencakup:

| Aspek | Solusi |
|---|---|
| **Data Film** | Integrasi API TMDB (The Movie Database) untuk informasi film real-time |
| **Backend & Auth** | Supabase (PostgreSQL + Auth + Storage) untuk data pengguna, review, diskusi, dan aktivitas |
| **Autentikasi** | Google Sign-In dengan alur OAuth2 yang aman via Supabase |
| **Penyimpanan Lokal** | SharedPreferences untuk cache offline watched/watchlist |
| **Onboarding Personal** | Pengisian genre favorit + pencarian dan pemilihan film yang pernah ditonton saat pertama kali membuka aplikasi |
| **Komunitas** | Sistem ulasan bintang, diskusi (thread) berbenang, like, komentar, dan sistem follow/following |

**Metode pengembangan** mengikuti pendekatan iteratif agile di mana fitur dikembangkan secara modular, diuji, lalu diintegrasikan secara bertahap dengan mengutamakan stabilitas (zero compile-error) di setiap iterasi.

### 1.5 Hasil dan Manfaat

Aplikasi **AfterCredits v1.0.0** berhasil membangun:

- ✅ Ekosistem komunitas film yang terintegrasi dalam satu aplikasi
- ✅ Sistem autentikasi aman berbasis Google Sign-In
- ✅ Feed discovery film dengan rekomendasi personal berdasarkan genre
- ✅ Manajemen riwayat tontonan dan watchlist yang tersinkronisasi ke cloud
- ✅ Sistem ulasan lengkap dengan rating bintang dan komentar
- ✅ Forum diskusi (thread) dengan sistem like dan balasan
- ✅ Halaman profil pengguna yang menampilkan statistik tontonan dan daftar genre favorit
- ✅ **Fitur Aktivitas Teman** yang menampilkan feed real-time dari akun yang diikuti
- ✅ APK release berukuran ±54 MB yang dapat didistribusikan langsung

**Manfaat utama** yang dihadirkan bagi pengguna:
- Pengalaman menonton film yang lebih terstruktur, tercatat, dan terhubung secara sosial
- Mendorong penemuan film baru melalui rekomendasi berbasis selera personal
- Membangun komunitas diskusi film berbahasa Indonesia yang terorganisir

---

## 2. Arsitektur & Struktur Teknis

### 2.1 Arsitektur Aplikasi

AfterCredits menggunakan arsitektur **Service-based Architecture** dengan pemisahan lapisan yang jelas:

```
┌─────────────────────────────────────────────┐
│                  UI Layer                   │
│  (Screens, Tabs, Widgets — Flutter Widgets) │
├─────────────────────────────────────────────┤
│               Service Layer                 │
│  (AuthService, TmdbService, ReviewService,  │
│   FollowService, UserProfileService, etc.)  │
├─────────────────────────────────────────────┤
│               Data Layer                    │
│  ┌─────────────────┐  ┌───────────────────┐ │
│  │  TMDB REST API  │  │  Supabase (Cloud) │ │
│  │ (Film & Cast)   │  │  (Auth + DB + STG)│ │
│  └─────────────────┘  └───────────────────┘ │
│  ┌─────────────────────────────────────────┐ │
│  │     SharedPreferences (Local Cache)     │ │
│  └─────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```

**Alur data utama:**
1. User login → `AuthService` → Google OAuth2 → Supabase JWT
2. Pencarian/browse film → `TmdbService` → TMDB API → `MovieModel`
3. Ulasan/diskusi → `ReviewCommunityService` / `CommunityService` → Supabase `reviews` / `threads`
4. Watched/Watchlist → `MovieUserDataService` → SharedPreferences (lokal) + Supabase `user_activities`
5. Feed aktivitas teman → `ReviewCommunityService.getFriendActivities()` → Supabase `follows` + `reviews` + `threads` + `user_activities`

**Skema Database Supabase:**

| Tabel | Kolom Utama | Fungsi |
|---|---|---|
| `profiles` | id, username, avatar_url, bio, genres | Profil pengguna |
| `reviews` | id, user_id, movie_id, movie_title, rating, text, created_at | Ulasan film |
| `threads` | id, author_id, title, content, category, created_at | Diskusi forum |
| `thread_comments` | id, thread_id, author_id, content, created_at | Komentar diskusi |
| `follows` | follower_id, following_id | Relasi follow/following |
| `user_activities` | id, user_id, action_type, movie_id, movie_title, created_at | Log watched/watchlist |

### 2.2 Teknologi dan Library yang Digunakan

| Kategori | Teknologi / Library | Versi | Keterangan |
|---|---|---|---|
| **Framework** | Flutter | SDK ^3.12.0 | Cross-platform mobile (Android/iOS/Web) |
| **Bahasa** | Dart | Sesuai Flutter SDK | Bahasa utama pengembangan |
| **Auth** | google_sign_in | ^6.2.1 | Google OAuth2 Sign-In |
| **Backend** | supabase_flutter | ^2.8.0 | Database, Auth, dan Storage cloud |
| **Data Film** | TMDB API (http) | http ^1.2.2 | REST API database film |
| **Lokal Storage** | shared_preferences | ^2.3.2 | Cache offline watched/watchlist |
| **UI/Fonts** | google_fonts | ^6.2.1 | Tipografi premium (Poppins, Inter) |
| **UI/Animation** | animate_do | ^3.3.4 | Animasi fade/slide pada widget |
| **UI/Image** | cached_network_image | ^3.4.1 | Lazy loading gambar poster film |
| **UI/Indicator** | smooth_page_indicator | ^1.2.0 | Indikator halaman onboarding |
| **Media** | image_picker | ^1.1.2 | Pengambilan foto untuk avatar profil |
| **Link** | url_launcher | ^6.3.1 | Membuka trailer YouTube di browser |

### 2.3 Struktur Folder Proyek

```
aftercredits/
├── lib/
│   ├── main.dart                          # Entry point + inisialisasi Supabase
│   ├── core/
│   │   ├── constants/
│   │   │   └── api_constants.dart         # API keys dan URL dasar TMDB
│   │   ├── services/
│   │   │   ├── auth_service.dart          # Google Sign-In + Supabase Auth
│   │   │   ├── supabase_service.dart      # Singleton instance Supabase client
│   │   │   ├── tmdb_service.dart          # Fetch film, populer, detail, cast
│   │   │   ├── movie_user_data_service.dart  # Watched/Watchlist + sync activities
│   │   │   ├── review_community_service.dart # Review, popular review, friend feed
│   │   │   ├── community_service.dart     # Thread, komentar, like, trending
│   │   │   ├── follow_service.dart        # Follow/unfollow + cek status
│   │   │   └── user_profile_service.dart  # Ambil & update profil pengguna
│   │   └── theme/
│   │       └── app_theme.dart             # Konstanta warna, teks, dan style global
│   ├── models/
│   │   ├── movie_model.dart               # Data model film dari TMDB
│   │   ├── cast_model.dart                # Data model pemeran film
│   │   ├── community_review_model.dart    # Model ulasan komunitas
│   │   ├── movie_review_model.dart        # Model ulasan lokal pengguna
│   │   └── user_profile_model.dart        # Model profil pengguna
│   ├── features/
│   │   ├── auth/
│   │   │   └── login_screen.dart          # Halaman login Google
│   │   ├── onboarding/
│   │   │   └── onboarding_screen.dart     # Alur onboarding multi-step
│   │   ├── setup/
│   │   │   └── setup_screen.dart          # Pengisian profil + genre favorit
│   │   ├── home/
│   │   │   ├── home_screen.dart           # Scaffolding tab utama
│   │   │   ├── see_all_movies_screen.dart # Halaman lihat semua film
│   │   │   └── tabs/
│   │   │       ├── discover_tab.dart      # Tab Jelajahi + hero banner + friend activity
│   │   │       ├── community_tab.dart     # Tab Komunitas + review populer + diskusi
│   │   │       ├── search_tab.dart        # Tab Pencarian film
│   │   │       ├── profile_tab.dart       # Tab Profil pengguna sendiri
│   │   │       ├── edit_profile_screen.dart
│   │   │       ├── settings_screen.dart
│   │   │       └── community/
│   │   │           ├── thread_detail_screen.dart  # Detail + balasan diskusi
│   │   │           ├── user_profile_screen.dart   # Profil pengguna lain
│   │   │           └── widgets/                   # Widget komunitas (card, header, dll.)
│   │   ├── movie_detail/
│   │   │   └── movie_detail_screen.dart   # Detail film + review + cast + trailer
│   │   └── review_detail/
│   │       └── review_detail_screen.dart  # Detail ulasan + komentar
│   └── shared/
│       └── widgets/
│           └── movie_card.dart            # Widget kartu film yang dapat digunakan ulang
├── assets/
│   └── images/                            # Aset gambar lokal
├── pubspec.yaml                           # Konfigurasi proyek dan dependency
└── build/app/outputs/flutter-apk/
    └── app-release.apk                    # APK release (54.4 MB)
```

---

## 3. Implementasi Aplikasi

### 3.1 Halaman Login

**Penanggung Jawab Fitur:** Tim Auth & UI

Halaman pertama yang dilihat pengguna baru. Menampilkan logo dan tagline aplikasi AfterCredits beserta tombol **"Masuk dengan Google"**. Autentikasi dilakukan melalui Google OAuth2 yang terintegrasi langsung dengan Supabase Auth.

**Fitur utama:**
- Tombol Sign-In Google dengan branding resmi
- Animasi fade-in saat halaman dimuat
- Navigasi otomatis ke Onboarding (pengguna baru) atau Home (pengguna lama)
- Penanganan error sign-in yang ramah pengguna

---

### 3.2 Onboarding (Pengenalan Awal)

**Penanggung Jawab Fitur:** Tim UX & Setup

Alur multi-langkah (3 step) yang hanya ditampilkan satu kali kepada pengguna baru:

| Step | Konten |
|---|---|
| Step 1 | Sambutan dan perkenalan AfterCredits |
| Step 2 | Pilih **genre film favorit** (min. 3 genre dari 12 pilihan) |
| Step 3 | Cari dan pilih **film yang pernah ditonton** untuk membangun riwayat awal |

**Fitur utama:**
- Progress indicator halaman (SmoothPageIndicator)
- Pemilihan genre dengan toggle visual berwarna
- **Pencarian film real-time** menggunakan TMDB API saat onboarding
- Penyimpanan genre favorit ke Supabase `profiles` dan riwayat ke `user_activities`

---

### 3.3 Tab Jelajahi (Discover Tab)

**Penanggung Jawab Fitur:** Tim Discovery & Rekomendasi

Tab utama yang berfungsi sebagai halaman beranda aplikasi. Menampilkan:

**a. Hero Banner Film Populer**
- Kartu besar dengan backdrop film yang sedang populer
- Tombol langsung untuk menambahkan ke Watchlist dari banner
- Auto-scroll dengan indikator halaman

**b. Film Rekomendasi Personal**
- Daftar film yang direkomendasikan berdasarkan genre favorit pengguna
- Tampilan horizontal scrollable dengan poster dan rating

**c. Hidden Gems**
- Film berkualitas tinggi (rating ≥7.0) dengan jumlah vote lebih rendah — menemukan film tersembunyi

**d. Aktivitas Teman (Following Feed)**
- Feed real-time aktivitas dari akun yang diikuti pengguna
- Menampilkan: review baru, diskusi baru, film yang ditonton, dan penambahan watchlist
- Kartu aktivitas yang dapat diklik untuk langsung menuju detail film, review, atau diskusi terkait
- Klik avatar/username untuk membuka profil pengguna tersebut

---

### 3.4 Tab Komunitas (Community Tab)

**Penanggung Jawab Fitur:** Tim Komunitas & Sosial

**a. Review Populer Minggu Ini**
- Menampilkan review terpopuler dari seluruh pengguna berdasarkan data Supabase `reviews`
- Rating bintang, foto profil reviewer, dan cuplikan teks ulasan
- Dapat diklik untuk melihat detail review lengkap

**b. Diskusi Tren (Trending Discussions)**
- Daftar thread diskusi film yang aktif dengan kategori
- Indikator jumlah komentar dan waktu posting

**c. Buat Diskusi Baru**
- Tombol FAB untuk membuat thread baru
- Form dengan judul, isi diskusi, dan pilihan kategori

---

### 3.5 Tab Pencarian (Search Tab)

**Penanggung Jawab Fitur:** Tim Search & Discovery

- Kotak pencarian real-time dengan debounce
- Hasil pencarian menampilkan poster, judul, tahun, dan rating
- State awal menampilkan film populer sebagai saran

---

### 3.6 Halaman Detail Film

**Penanggung Jawab Fitur:** Tim Film Detail & Review

**a. Header Visual**
- Backdrop film fullscreen dengan efek gradien
- Poster, judul, tagline, tahun rilis, durasi, dan genre badge
- Rating rata-rata TMDB

**b. Aksi Pengguna**
- Tombol **Watched** dan **Watchlist** dengan state persisten (tersinkron ke cloud)

**c. Informasi Film**
- Sinopsis, daftar pemeran (cast) dengan foto, tombol trailer YouTube

**d. Ulasan Komunitas**
- Daftar ulasan pengguna lain untuk film ini

**e. Form Tulis Ulasan**
- Rating bintang interaktif (1–5) dan area teks ulasan
- Disimpan ke Supabase `reviews`

---

### 3.7 Detail Ulasan & Komentar

**Penanggung Jawab Fitur:** Tim Review & Komentar

- Ulasan lengkap dengan rating bintang
- Daftar komentar dengan timestamp
- Form komentar baru dan fitur like ulasan
- Tap reviewer untuk buka profil

---

### 3.8 Diskusi (Thread Detail)

**Penanggung Jawab Fitur:** Tim Forum & Diskusi

- Konten diskusi lengkap dari pembuat thread
- Daftar balasan berurutan
- **Fitur hapus** bagi pemilik thread/komentar
- Form balasan yang terintegrasi

---

### 3.9 Tab Profil (Profile Tab)

**Penanggung Jawab Fitur:** Tim Profil & Statistik

- Header profil: foto, username, bio, jumlah Following/Followers
- Statistik: total film ditonton, watchlist, dan ulasan
- Genre favorit dan "Movie Taste" (distribusi genre dari riwayat tontonan)
- Daftar Watched, Watchlist, dan Ulasan milik pengguna

---

### 3.10 Profil Pengguna Lain

**Penanggung Jawab Fitur:** Tim Komunitas & Sosial

- Dapat diakses dari mana saja dengan tap avatar/username
- Tombol Follow/Unfollow yang aktif
- Statistik, genre favorit, review, dan diskusi pengguna tersebut

---

### 3.11 Edit Profil & Pengaturan

**Penanggung Jawab Fitur:** Tim Pengaturan

- Ganti foto profil, username, dan bio
- Manajemen genre favorit dan opsi Sign Out

---

## 4. Kesimpulan

### 4.1 Pencapaian Proyek

| Tujuan | Status |
|---|---|
| Aplikasi komunitas film mobile berbasis Flutter | ✅ Selesai |
| Integrasi TMDB API untuk data film real-time | ✅ Selesai |
| Autentikasi Google Sign-In via Supabase | ✅ Selesai |
| Manajemen watched/watchlist tersinkron ke cloud | ✅ Selesai |
| Sistem ulasan bintang dan komentar | ✅ Selesai |
| Forum diskusi dengan thread dan balasan | ✅ Selesai |
| Sistem follow/following antar pengguna | ✅ Selesai |
| Feed aktivitas teman (Following Activity) | ✅ Selesai |
| Rekomendasi film personal berbasis genre | ✅ Selesai |
| Build APK release yang dapat didistribusikan | ✅ Selesai (54.4 MB) |

### 4.2 Keterbatasan Aplikasi

1. **Tabel `user_activities` opsional** — Fitur pencatatan aktivitas baru berfungsi penuh setelah tabel `user_activities` dibuat di SQL Editor Supabase.
2. **Offline support terbatas** — Sebagian besar fitur memerlukan koneksi internet; hanya watched/watchlist yang di-cache secara lokal.
3. **Notifikasi push belum tersedia** — Belum ada notifikasi ketika teman beraktivitas atau ulasan mendapat komentar.
4. **Hanya dark mode** — Belum ada toggle antara tema gelap dan terang.
5. **Pencarian terbatas pada film** — Belum mencakup pencarian pengguna, thread, atau ulasan.
6. **Feed tidak diperbarui otomatis** — Diperlukan refresh manual untuk melihat aktivitas teman terbaru.

### 4.3 Pengembangan di Masa Depan

| Fitur | Prioritas | Keterangan |
|---|---|---|
| **Push Notification** | 🔴 Tinggi | Notifikasi like, komentar, dan follower baru via Firebase FCM |
| **Pencarian Universal** | 🔴 Tinggi | Pencarian pengguna, thread, dan ulasan |
| **Real-time Updates** | 🔴 Tinggi | Supabase Realtime untuk update feed tanpa refresh |
| **Daftar Kurator Film** | 🟡 Sedang | Fitur membuat dan berbagi "List Film" |
| **Rating Komunitas** | 🟡 Sedang | Rata-rata rating dari seluruh pengguna AfterCredits per film |
| **Pencapaian & Badge** | 🟡 Sedang | Gamifikasi: badge "100 Film Ditonton", "Reviewer Aktif", dll. |
| **Light Mode** | 🟡 Sedang | Toggle antara tema gelap dan terang |
| **Multi-bahasa** | 🟢 Rendah | Dukungan Bahasa Inggris selain Bahasa Indonesia |
| **iOS Release** | 🟢 Rendah | Konfigurasi dan distribusi untuk platform iOS |

---

*Dokumentasi ini dibuat berdasarkan kondisi kode sumber AfterCredits versi 1.0.0 per Juli 2026.*
