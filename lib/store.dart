import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const categories = ['Semua', 'Perlengkapan', 'Elektronik', 'Buku', 'Aksesori'];
const reportTypes = ['Semua', 'Hilang', 'Ditemukan'];

class ItemReport {
  ItemReport({
    required this.id,
    required this.title,
    required this.type,
    required this.category,
    required this.location,
    required this.description,
    required this.date,
    required this.owner,
    required this.schoolClass,
    this.resolved = false,
  });
  final String id,
      title,
      type,
      category,
      location,
      description,
      date,
      owner,
      schoolClass;
  bool resolved;
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'type': type,
    'category': category,
    'location': location,
    'description': description,
    'date': date,
    'owner': owner,
    'schoolClass': schoolClass,
    'resolved': resolved,
  };
  factory ItemReport.fromJson(Map<String, dynamic> j) {
    for (final key in [
      'id',
      'title',
      'type',
      'category',
      'location',
      'description',
      'date',
      'owner',
      'schoolClass',
    ]) {
      if (j[key] is! String) {
        throw const FormatException('Format laporan tidak valid');
      }
    }
    return ItemReport(
      id: j['id'],
      title: j['title'],
      type: j['type'],
      category: j['category'],
      location: j['location'],
      description: j['description'],
      date: j['date'],
      owner: j['owner'],
      schoolClass: j['schoolClass'],
      resolved: j['resolved'] == true,
    );
  }
}

class AppStore extends ChangeNotifier {
  static const storageKey = 'lost_found_school_v1';
  List<ItemReport> items = [];
  Set<String> savedIds = {};
  String userName = '',
      schoolClass = '',
      query = '',
      typeFilter = 'Semua',
      categoryFilter = 'Semua';
  String? error;
  bool loading = true, dark = false;
  int tab = 0;
  Map<String, String> draft = emptyDraft();
  SharedPreferences? _prefs;
  Future<void> _pending = Future.value();
  static Map<String, String> emptyDraft() => {
    'title': '',
    'location': '',
    'description': '',
    'type': 'Hilang',
    'category': 'Perlengkapan',
    'date': DateTime.now().toIso8601String().substring(0, 10),
  };

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      _prefs = await SharedPreferences.getInstance();
      final raw = _prefs!.getString(storageKey);
      if (raw == null) {
        items = seedItems();
      } else {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        final loaded = (j['items'] as List)
            .map((v) => ItemReport.fromJson(Map<String, dynamic>.from(v)))
            .toList();
        final loadedDraft = Map<String, String>.from(j['draft']);
        if (!emptyDraft().keys.every(loadedDraft.containsKey)) {
          throw const FormatException('Draf tidak lengkap');
        }
        items = loaded;
        draft = loadedDraft;
        savedIds = Set<String>.from(j['saved']);
        userName = j['userName'] as String;
        schoolClass = j['schoolClass'] as String;
        dark = j['dark'] == true;
      }
    } catch (_) {
      error =
          'Data lokal tidak dapat dibaca. Coba lagi atau pulihkan data demo.';
    }
    loading = false;
    notifyListeners();
  }

  Future<void> _save() {
    final snapshot = jsonEncode({
      'items': items.map((i) => i.toJson()).toList(),
      'saved': savedIds.toList(),
      'userName': userName,
      'schoolClass': schoolClass,
      'dark': dark,
      'draft': draft,
    });
    _pending = _pending.then((_) async {
      try {
        if (_prefs == null || !await _prefs!.setString(storageKey, snapshot)) {
          throw StateError('Penyimpanan gagal');
        }
      } catch (_) {
        error =
            'Perubahan ada di memori, tetapi gagal disimpan. Coba simpan lagi.';
        notifyListeners();
      }
    });
    return _pending;
  }

  Future<void> flush() => _pending;
  Future<void> retrySave() async {
    error = null;
    await _save();
    notifyListeners();
  }

  String? login(String name, String kelas) {
    if (name.trim().length < 3) {
      return 'Nama minimal 3 karakter.';
    }
    if (kelas.trim().isEmpty) {
      return 'Kelas wajib diisi.';
    }
    userName = name.trim();
    schoolClass = kelas.trim();
    _save();
    notifyListeners();
    return null;
  }

  void logout() {
    userName = '';
    schoolClass = '';
    tab = 0;
    _save();
    notifyListeners();
  }

  void setTab(int value) {
    tab = value;
    notifyListeners();
  }

  void filter({String? query, String? type, String? category}) {
    if (query != null) {
      this.query = query;
    }
    if (type != null) {
      typeFilter = type;
    }
    if (category != null) {
      categoryFilter = category;
    }
    notifyListeners();
  }

  List<ItemReport> get filtered => items
      .where(
        (i) =>
            (typeFilter == 'Semua' || i.type == typeFilter) &&
            (categoryFilter == 'Semua' || i.category == categoryFilter) &&
            '${i.title} ${i.location} ${i.description}'.toLowerCase().contains(
              query.trim().toLowerCase(),
            ),
      )
      .toList();
  ItemReport item(String id) => items.firstWhere((i) => i.id == id);
  bool isMine(ItemReport i) =>
      i.owner == userName && i.schoolClass == schoolClass;
  void updateDraft(String key, String value) {
    draft[key] = value;
    _save();
  }

  String? validateDraft() {
    if ((draft['title'] ?? '').trim().length < 3) {
      return 'Nama barang minimal 3 karakter.';
    }
    if ((draft['location'] ?? '').trim().length < 3) {
      return 'Lokasi minimal 3 karakter.';
    }
    if ((draft['description'] ?? '').trim().length < 10) {
      return 'Ciri-ciri barang minimal 10 karakter.';
    }
    final date = DateTime.tryParse(draft['date'] ?? '');
    if (date == null ||
        date.toIso8601String().substring(0, 10) != draft['date'] ||
        date.isAfter(DateTime.now())) {
      return 'Tanggal harus valid dan tidak boleh di masa depan.';
    }
    if (!reportTypes.skip(1).contains(draft['type']) ||
        !categories.skip(1).contains(draft['category'])) {
      return 'Pilih jenis dan kategori yang tersedia.';
    }
    return null;
  }

  Future<String?> submitDraft() async {
    if (userName.isEmpty || validateDraft() != null) {
      return null;
    }
    final id = 'LF-${DateTime.now().microsecondsSinceEpoch}';
    items.insert(
      0,
      ItemReport(
        id: id,
        title: draft['title']!.trim(),
        type: draft['type']!,
        category: draft['category']!,
        location: draft['location']!.trim(),
        description: draft['description']!.trim(),
        date: draft['date']!,
        owner: userName,
        schoolClass: schoolClass,
      ),
    );
    draft = emptyDraft();
    await _save();
    notifyListeners();
    return id;
  }

  Future<void> toggleSaved(String id) async {
    if (!items.any((i) => i.id == id)) {
      return;
    }
    savedIds.contains(id) ? savedIds.remove(id) : savedIds.add(id);
    await _save();
    notifyListeners();
  }

  Future<bool> resolve(String id) async {
    final i = item(id);
    if (!isMine(i) || i.resolved) {
      return false;
    }
    i.resolved = true;
    await _save();
    notifyListeners();
    return true;
  }

  Future<void> setDark(bool value) async {
    dark = value;
    await _save();
    notifyListeners();
  }

  Future<void> resetDemo() async {
    items = seedItems();
    savedIds = {};
    draft = emptyDraft();
    query = '';
    typeFilter = 'Semua';
    categoryFilter = 'Semua';
    error = null;
    await _save();
    notifyListeners();
  }
}

List<ItemReport> seedItems() => [
  ItemReport(
    id: 'LF-001',
    title: 'Botol minum hijau',
    type: 'Ditemukan',
    category: 'Perlengkapan',
    location: 'Lapangan basket',
    description: 'Botol stainless hijau dengan stiker daun. Dititipkan di ruang tata usaha.',
    date: '2026-11-12',
    owner: 'Siswa Demo A',
    schoolClass: 'XI IPA 1',
  ),
  ItemReport(
    id: 'LF-002',
    title: 'Kalkulator ilmiah',
    type: 'Hilang',
    category: 'Elektronik',
    location: 'Laboratorium fisika',
    description: 'Kalkulator hitam dengan tulisan nama di bagian belakang dan penutup abu-abu.',
    date: '2026-11-12',
    owner: 'Siswa Demo B',
    schoolClass: 'X IPA 2',
  ),
  ItemReport(
    id: 'LF-003',
    title: 'Buku catatan matematika',
    type: 'Ditemukan',
    category: 'Buku',
    location: 'Perpustakaan',
    description: 'Sampul cokelat dengan label Matematika. Disimpan di meja petugas perpustakaan.',
    date: '2026-11-11',
    owner: 'Siswa Demo C',
    schoolClass: 'XII IPA 1',
  ),
  ItemReport(
    id: 'LF-004',
    title: 'Dompet kartu biru',
    type: 'Hilang',
    category: 'Aksesori',
    location: 'Kantin sekolah',
    description:
        'Dompet kartu kecil berwarna biru tua dengan gantungan tali putih.',
    date: '2026-11-11',
    owner: 'Siswa Demo D',
    schoolClass: 'XI IPS 1',
  ),
  ItemReport(
    id: 'LF-005',
    title: 'Kunci dengan gantungan bola',
    type: 'Ditemukan',
    category: 'Aksesori',
    location: 'Koridor kelas X',
    description: 'Dua kunci perak dengan gantungan berbentuk bola. Dititipkan di pos satpam.',
    date: '2026-11-10',
    owner: 'Siswa Demo E',
    schoolClass: 'X IPS 2',
  ),
  ItemReport(
    id: 'LF-006',
    title: 'Tas olahraga hitam',
    type: 'Hilang',
    category: 'Perlengkapan',
    location: 'Ruang ganti olahraga',
    description: 'Tas serut hitam dengan garis putih. Berisi pakaian olahraga dan handuk kecil.',
    date: '2026-11-10',
    owner: 'Siswa Demo F',
    schoolClass: 'XII IPS 1',
  ),
];
