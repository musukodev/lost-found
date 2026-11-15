import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:temu_sekolah/main.dart';
import 'package:temu_sekolah/store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final size in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(768, 1024),
    const Size(844, 390),
    const Size(1440, 900),
  ]) {
    for (final dark in [false, true]) {
      testWidgets(
        'layout ${size.width}x${size.height}, gelap=$dark, setiap tujuan dan formulir',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          SharedPreferences.setMockInitialValues({});
          final s = AppStore();
          await s.load();
          s.login('Penguji Demo', 'XI IPA 1');
          await s.setDark(dark);
          await tester.pumpWidget(LostFoundApp(store: s));
          await tester.pumpAndSettle();
          for (final tab in [1, 2, 3, 0]) {
            s.setTab(tab);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
          s.setTab(2);
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byKey(const Key('report-title')),
            'Draf orientasi',
          );
          tester.view.physicalSize = Size(size.height, size.width);
          await tester.pumpAndSettle();
          expect(find.text('Draf orientasi'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets('filter kosong, simpanan kosong, dialog batal, tema dan keluar', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final s = AppStore();
    await s.load();
    s.login('Penguji Demo', 'XI');
    await tester.pumpWidget(LostFoundApp(store: s));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Barang tersimpan'));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada barang tersimpan'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    s.setTab(1);
    s.filter(query: 'tidak-ada-barang');
    await tester.pumpAndSettle();
    expect(find.text('Barang belum cocok'), findsOneWidget);
    await tester.ensureVisible(find.text('Hapus filter'));
    await tester.tap(find.text('Hapus filter'));
    await tester.pumpAndSettle();
    expect(s.query, isEmpty);
    expect(find.text('tidak-ada-barang'), findsNothing);
    await tester.tap(find.byTooltip('Pengaturan'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(s.dark, isTrue);
    await tester.ensureVisible(find.text('Pulihkan data demo'));
    await tester.tap(find.text('Pulihkan data demo'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    await tester.ensureVisible(find.text('Keluar demo'));
    await tester.tap(find.text('Keluar demo'));
    await tester.pumpAndSettle();
    expect(find.text('Masuk ke papan barang'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
