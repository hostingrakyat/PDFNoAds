class AppStrings {
  static const Map<String, Map<String, String>> _strings = {
    'en': {
      'appName': 'PDF No Ads',
      'tagline': 'Free PDF Reader · No Ads · Forever',
      'selectLanguage': 'Select Language',
      'english': 'English',
      'indonesian': 'Bahasa Indonesia',
      'continue': 'Continue',
      'recentFiles': 'Recent Files',
      'noRecentFiles': 'No recent files.\nTap the button below to open a PDF.',
      'openPdf': 'Open PDF',
      'openFile': 'Open File',
      'page': 'Page',
      'of': 'of',
      'setDefault': 'Set as Default PDF App',
      'setDefaultDesc': 'Open PDF files automatically with PDF No Ads',
      'defaultSet': 'Go to Settings to set default app',
      'share': 'Share',
      'createdBy': 'Created by: Ir. Riovan Styx Roring',
      'settings': 'Settings',
      'about': 'About',
      'aboutText': 'PDF No Ads v1.0.0\nFree. No Ads. Forever.\n\nPart of the 365 Days App Challenge\n1 day · 1 app · No ads',
      'zoomIn': 'Zoom In',
      'zoomOut': 'Zoom Out',
      'night': 'Night Mode',
      'followUs': 'Follow Us',
    },
    'id': {
      'appName': 'PDF No Ads',
      'tagline': 'Pembaca PDF Gratis · Tanpa Iklan · Selamanya',
      'selectLanguage': 'Pilih Bahasa',
      'english': 'English',
      'indonesian': 'Bahasa Indonesia',
      'continue': 'Lanjutkan',
      'recentFiles': 'File Terakhir',
      'noRecentFiles': 'Belum ada file.\nKetuk tombol di bawah untuk membuka PDF.',
      'openPdf': 'Buka PDF',
      'openFile': 'Buka File',
      'page': 'Halaman',
      'of': 'dari',
      'setDefault': 'Jadikan Aplikasi PDF Default',
      'setDefaultDesc': 'Buka file PDF otomatis dengan PDF No Ads',
      'defaultSet': 'Buka Pengaturan untuk mengatur aplikasi default',
      'share': 'Bagikan',
      'createdBy': 'Dibuat oleh: Ir. Riovan Styx Roring',
      'settings': 'Pengaturan',
      'about': 'Tentang',
      'aboutText': 'PDF No Ads v1.0.0\nGratis. Tanpa Iklan. Selamanya.\n\nBagian dari 365 Hari Tantangan Aplikasi\n1 hari · 1 aplikasi · Tanpa iklan',
      'zoomIn': 'Perbesar',
      'zoomOut': 'Perkecil',
      'night': 'Mode Malam',
      'followUs': 'Ikuti Kami',
    },
  };

  final String locale;

  AppStrings(this.locale);

  String get(String key) {
    return _strings[locale]?[key] ?? _strings['en']![key] ?? key;
  }
}
