# Mini POS System (Fast Offline Cashier)

Aplikasi Point of Sale (POS) berbasis Flutter yang berjalan **100% offline** untuk operasional kasir F&B dan retail.

### Cara Menjalankan
1. Salin `.env.example` menjadi `.env`:
   ```bash
   cp .env.example .env
   ```
2. Install dependensi dan jalankan:
   ```bash
   flutter pub get
   flutter run
   ```

---

## 1. Project Architecture

Proyek ini menggunakan **Feature-First 2-Layer Architecture** (`data` + `presentation`) dengan shared `core/` dan **Dependency Injection (`get_it`)**:

- **`lib/core/`**: Konfigurasi lingkungan (`.env` via `flutter_dotenv`), tema, helper responsif (`ResponsiveLayout`), SQLite helper (`AppDatabase`), penyimpanan sesi aman (`SecureSessionService` dengan `flutter_secure_storage`), penyimpanan foto permanen (`ImageStorageService` dengan `path_provider` + `path`), formatter, dan reusable widgets.
- **`lib/features/<feature>/data/`**:
  - `models/`: Representasi data dan serialisasi `Map`/JSON.
  - `datasources/`: Query langsung ke SQLite (`sqflite`) termasuk *atomic transaction*.
  - `repositories/`: Abstraksi akses data sehingga `presentation/` (BLoC/UI) tidak berinteraksi langsung dengan query mentah.
  - `services/`: Business logic bersama (seperti `StockValidator`).
- **`lib/features/<feature>/presentation/`**:
  - `bloc/`: State management (`AuthBloc`, `CategoryBloc`, `ProductBloc`, `AddonBloc`, `CartBloc`, `ReportBloc`).
  - `pages/` & `widgets/`: Halaman dan komponen UI responsif.

Fitur yang tersedia:
1. `auth`: Splash check session, Register, Login offline (SHA-256 + random salt), Logout.
2. `master_data`: CRUD Kategori, Produk (foto kamera/galeri tersimpan permanen), dan Add-on/Topping (stok terpisah).
3. `pos`: Katalog cepat dengan search & filter kategori, manajemen keranjang & add-on, validasi stok akumulatif, proteksi diskon, pembayaran tunai, dan preview struk digital.
4. `report`: Dashboard penjualan offline, filter tanggal, grafik pendapatan harian, produk terlaris, dan detail struk riwayat transaksi.

---

## 2. State Management

Menggunakan **BLoC (`flutter_bloc` + `equatable`)** dengan pemisahan jelas antara UI (`pages`/`widgets`), state/events (`bloc`), dan akses data (`repositories`):
- `AuthBloc`: Mengelola pemeriksaan sesi lokal, login, registrasi, dan logout.
- `CategoryBloc`, `ProductBloc`, `AddonBloc`: Mengelola CRUD master data dan filter katalog.
- `CartBloc`: Mengelola keranjang, penggabungan item identik, *shared stock validation*, diskon, *hold bill*, dan proses checkout atomik.
- `ReportBloc`: Mengelola filter rentang tanggal, agregasi analitik penjualan, dan pembacaan detail struk historis.

---

## 3. Database Table Structure (SQLite)

Seluruh tabel relasional didefinisikan di `lib/core/database/app_database.dart` dengan `PRAGMA foreign_keys = ON`:

1. **`cashiers`**: `id`, `name`, `username` (UNIQUE), `password_hash`, `created_at`
2. **`categories`**: `id`, `name` (UNIQUE), `created_at`
3. **`products`**: `id`, `category_id` (FK $\rightarrow$ `categories.id`), `name`, `price`, `stock`, `image_path`, `is_deleted`, `created_at`, `updated_at`
4. **`addons`**: `id`, `name`, `price`, `stock`, `is_deleted`, `created_at`, `updated_at`
5. **`transactions`**: `id`, `invoice_number` (UNIQUE), `cashier_id` (FK, `ON DELETE SET NULL`), `cashier_name_snapshot`, `subtotal`, `discount_type`, `discount_value`, `discount_amount`, `total`, `cash_received`, `change_amount`, `created_at`
6. **`transaction_items`**: `id`, `transaction_id` (FK, `ON DELETE CASCADE`), `product_id` (FK, `ON DELETE SET NULL`), `product_name_snapshot`, `unit_price_snapshot`, `quantity`, `item_subtotal`
7. **`transaction_item_addons`**: `id`, `transaction_item_id` (FK, `ON DELETE CASCADE`), `addon_id` (FK, `ON DELETE SET NULL`), `addon_name_snapshot`, `addon_price_snapshot`, `quantity`
8. **`held_orders`**: `id`, `label`, `cart_json`, `created_at`

### Solusi Logic & Hardship Challenges
- **Shared Stock Validation:** `StockValidator` menghitung total konsumsi stok produk dan add-on secara akumulatif di seluruh baris keranjang (termasuk produk yang sama dengan varian add-on berbeda).
- **Transaction History Immutability:** Detail transaksi menyimpan kolom `*_snapshot` serta memakai *soft delete* (`is_deleted`), sehingga perubahan harga atau penghapusan produk/add-on tidak memengaruhi struk dan laporan lama.
- **Offline Photo Persistence:** Foto kamera/galeri disalin ke `ApplicationDocumentsDirectory/product_images/` agar tidak hilang saat aplikasi ditutup atau cache sistem dibersihkan.
- **Discount Calculation Protection:** `DiscountModel` menolak diskon negatif, persentase `> 100%`, nominal `> subtotal`, serta memastikan total tagihan selalu $\ge 0$.

---

## 4. Bonus Features Implemented

- **SQLite Relational Schema & Atomic Transactions:** Validasi ulang stok, pengurangan stok produk & add-on, serta penyimpanan transaksi dilakukan di dalam satu `db.transaction(...)`.
- **Responsive Layout (Mobile, Tablet Portrait & Tablet Landscape):** Layar kasir otomatis menyesuaikan menjadi *split-screen* pada tablet dan *bottom cart bar + sheet* pada mobile.
- **Sales Dashboard Analytics:** Grafik pendapatan harian interaktif, ringkasan KPI (total omzet, jumlah transaksi, rata-rata order, total item terjual), daftar produk terlaris, serta filter tanggal (*Hari Ini*, *7 Hari*, *30 Hari*, *Semua*, *Custom Range*).
- **Hold / Save Bill:** Simpan pesanan sementara dengan label dan muat kembali ke keranjang (disertai validasi ulang stok).
- **Quick Cash:** Tombol nominal cepat (*Uang Pas*, *Rp 10.000*, *Rp 20.000*, *Rp 50.000*, *Rp 100.000*) pada halaman pembayaran.
- **Low Stock Indicator:** Badge indikator stok rendah dan stok habis pada master data dan katalog kasir.
