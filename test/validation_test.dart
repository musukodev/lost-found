import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:temu_sekolah/store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<AppStore> fresh() async {
    SharedPreferences.setMockInitialValues({});
    final s = AppStore();
    await s.load();
    return s;
  }

  test('laporan kosong dan tanggal tidak valid tidak ditambahkan', () async {
    final s = await fresh();
    s.login('Penguji', 'XI');
    final count = s.items.length;
    expect(await s.submitDraft(), isNull);
    s.updateDraft('title', 'Buku tulis');
    s.updateDraft('location', 'Kantin');
    s.updateDraft('description', 'Buku catatan dengan sampul hijau');
    for (final date in ['2026-02-30', '2099-01-01', 'abc']) {
      s.updateDraft('date', date);
      expect(await s.submitDraft(), isNull);
    }
    expect(s.items.length, count);
  });
  test(
    'filter menggabungkan teks, jenis dan kategori; hasil kosong aman',
    () async {
      final s = await fresh();
      s.filter(query: 'PERPUSTAKAAN', type: 'Ditemukan', category: 'Buku');
      expect(s.filtered.single.id, 'LF-003');
      s.filter(type: 'Hilang');
      expect(s.filtered, isEmpty);
      s.filter(query: '', type: 'Semua', category: 'Semua');
      expect(s.filtered.length, s.items.length);
    },
  );
  test('laporan orang lain tidak dapat diselesaikan', () async {
    final s = await fresh();
    s.login('Penguji', 'XI');
    expect(await s.resolve('LF-001'), isFalse);
    expect(s.item('LF-001').resolved, isFalse);
  });
  test('data rusak dapat dipulihkan tanpa aplikasi crash', () async {
    SharedPreferences.setMockInitialValues({AppStore.storageKey: '{rusak'});
    final s = AppStore();
    await s.load();
    expect(s.error, isNotNull);
    await s.resetDemo();
    expect(s.error, isNull);
    expect(s.items, isNotEmpty);
  });
  test('tema dan draf bertahan; logout tidak menghapus laporan', () async {
    final s = await fresh();
    s.login('Penguji', 'XI');
    s.updateDraft('title', 'Draf tetap');
    await s.setDark(true);
    await s.flush();
    final again = AppStore();
    await again.load();
    expect(again.dark, isTrue);
    expect(again.draft['title'], 'Draf tetap');
    again.logout();
    await again.flush();
    expect(again.userName, isEmpty);
    expect(again.items, isNotEmpty);
  });
}
