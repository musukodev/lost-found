import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:temu_sekolah/main.dart';
import 'package:temu_sekolah/store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'siswa masuk, mencari, menyimpan, membuat dan menyelesaikan laporan',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final store = AppStore();
      await store.load();
      await tester.pumpWidget(LostFoundApp(store: store));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Masuk ke papan barang'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Masuk demo'));
      await tester.pumpAndSettle();
      expect(find.text('Nama minimal 3 karakter.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('login-name')),
        'Penguji Demo',
      );
      await tester.enterText(find.byKey(const Key('login-class')), 'XI IPA 1');
      await tester.pump();
      expect(find.text('Nama minimal 3 karakter.'), findsNothing);
      await tester.tap(find.widgetWithText(FilledButton, 'Masuk demo'));
      await tester.pumpAndSettle();
      expect(find.text('Papan barang sekolah'), findsOneWidget);
      await tester.tap(find.byKey(const Key('nav-search')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('search-field')),
        'kalkulator',
      );
      await tester.pumpAndSettle();
      expect(find.text('Kalkulator ilmiah'), findsOneWidget);
      expect(find.text('Botol minum hijau'), findsNothing);
      await tester.tap(find.text('Kalkulator ilmiah'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('save-item')));
      await tester.tap(find.byKey(const Key('save-item')));
      await tester.pumpAndSettle();
      expect(store.savedIds, contains('LF-002'));
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('nav-create')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('report-title')),
        'Payung pengujian',
      );
      await tester.enterText(
        find.byKey(const Key('report-location')),
        'Perpustakaan',
      );
      await tester.enterText(
        find.byKey(const Key('report-description')),
        'Payung hijau dengan gagang kayu.',
      );
      await tester.tap(find.byKey(const Key('nav-home')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('nav-create')));
      await tester.pumpAndSettle();
      expect(find.text('Payung pengujian'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('submit-report')));
      await tester.tap(find.byKey(const Key('submit-report')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('Payung pengujian'), findsOneWidget);
      await tester.tap(find.text('Payung pengujian'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Tandai selesai'));
      await tester.tap(find.text('Tandai selesai'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ya, sudah selesai'));
      await tester.pumpAndSettle();
      expect(store.items.first.resolved, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}
