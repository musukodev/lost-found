import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:temu_sekolah/main.dart';
import 'package:temu_sekolah/store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'jenis, kategori, panduan mengambil dan hapus simpanan berfungsi',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final s = AppStore();
      await s.load();
      s.login('Penguji', 'XI');
      s.setTab(1);
      await tester.pumpWidget(LostFoundApp(store: s));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Ditemukan'));
      await tester.pumpAndSettle();
      expect(s.typeFilter, 'Ditemukan');
      expect(find.text('Kalkulator ilmiah'), findsNothing);
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Buku').last);
      await tester.pumpAndSettle();
      expect(s.categoryFilter, 'Buku');
      expect(find.text('Buku catatan matematika'), findsOneWidget);
      await tester.ensureVisible(find.text('Buku catatan matematika'));
      await tester.tap(find.text('Buku catatan matematika'));
      await tester.pumpAndSettle();
      final save = find.byKey(const Key('save-item'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(s.savedIds, contains('LF-003'));
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(s.savedIds, isEmpty);
      await tester.ensureVisible(find.text('Cara mengambil barang'));
      await tester.tap(find.text('Cara mengambil barang'));
      await tester.pumpAndSettle();
      expect(find.text('Cocokkan dengan petugas'), findsOneWidget);
      await tester.tap(find.text('Mengerti'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'pemulihan data demo memerlukan konfirmasi dan benar-benar menghapus draf',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final s = AppStore();
      await s.load();
      s.login('Penguji', 'XI');
      s.updateDraft('title', 'Draf lama');
      await s.toggleSaved('LF-001');
      await tester.pumpWidget(LostFoundApp(store: s));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Pengaturan'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Pulihkan data demo'));
      await tester.tap(find.text('Pulihkan data demo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(s.draft['title'], 'Draf lama');
      await tester.tap(find.text('Pulihkan data demo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pulihkan data'));
      await tester.pumpAndSettle();
      expect(s.draft['title'], '');
      expect(s.savedIds, isEmpty);
      expect(s.userName, 'Penguji');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('layar pemuatan dan pemulihan data rusak memiliki aksi nyata', (
    tester,
  ) async {
    final s = AppStore();
    await tester.pumpWidget(LostFoundApp(store: s));
    await tester.pump();
    expect(find.text('Memuat papan barang sekolah...'), findsOneWidget);
    SharedPreferences.setMockInitialValues({AppStore.storageKey: 'broken'});
    await s.load();
    await tester.pumpAndSettle();
    expect(find.text('Data lokal belum terbaca'), findsOneWidget);
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(s.error, isNotNull);
    await tester.tap(find.text('Pulihkan data demo'));
    await tester.pumpAndSettle();
    expect(find.text('Masuk ke papan barang'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
