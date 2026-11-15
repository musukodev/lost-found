import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:temu_sekolah/store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'laporan baru, draf, simpanan dan sesi bertahan setelah store dibuka ulang',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = AppStore();
      await store.load();
      expect(store.items, isNotEmpty);
      expect(store.login('', ''), isNotNull);
      expect(store.login('Siswa Demo', 'XI IPA 1'), isNull);
      store.updateDraft('title', 'Payung hijau');
      store.updateDraft('location', 'Perpustakaan');
      store.updateDraft('description', 'Payung lipat dengan gagang kayu.');
      store.updateDraft('date', '2026-11-12');
      final id = await store.submitDraft();
      expect(id, isNotNull);
      await store.toggleSaved(id!);
      await store.flush();
      final reopened = AppStore();
      await reopened.load();
      expect(reopened.userName, 'Siswa Demo');
      expect(reopened.item(id).title, 'Payung hijau');
      expect(reopened.savedIds, contains(id));
      expect(reopened.draft['title'], '');
      expect(await reopened.resolve(id), isTrue);
      await reopened.flush();
      final again = AppStore();
      await again.load();
      expect(again.item(id).resolved, isTrue);
    },
  );
}
