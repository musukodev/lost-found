import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:temu_sekolah/main.dart';
import 'package:temu_sekolah/store.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Android: laporan, rotasi, simpanan dan pemulihan sesi lokal', (
    tester,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppStore.storageKey);
    final store = AppStore();
    await store.load();
    await tester.pumpWidget(LostFoundApp(store: store));
    await tester.pumpAndSettle();
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    Future<void> shot(String name) async {
      await tester.pumpAndSettle();
      await binding.takeScreenshot(name);
    }

    Future<void> tap(Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    await shot('android-01-pembuka');
    await tap(find.text('Masuk ke papan barang'));
    await tap(find.widgetWithText(FilledButton, 'Masuk demo'));
    expect(find.text('Nama minimal 3 karakter.'), findsOneWidget);
    await shot('android-02-validasi-login');
    await tester.enterText(
      find.byKey(const Key('login-name')),
      'Fawwaz Khairiy Wahid',
    );
    await tester.enterText(
      find.byKey(const Key('login-class')),
      'TRPL 3B PAGI',
    );
    await shot('android-03-login');
    await tap(find.widgetWithText(FilledButton, 'Masuk demo'));
    await shot('android-04-beranda');
    await tap(find.byKey(const Key('nav-search')));
    await tester.enterText(find.byKey(const Key('search-field')), 'kalkulator');
    await tester.pumpAndSettle();
    expect(find.text('Botol minum hijau'), findsNothing);
    await shot('android-05-pencarian');
    await tap(find.text('Kalkulator ilmiah'));
    await shot('android-06-detail');
    await tap(find.byKey(const Key('save-item')));
    expect(store.savedIds, contains('LF-002'));
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tap(find.byTooltip('Barang tersimpan'));
    await shot('android-07-tersimpan');
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tap(find.byKey(const Key('nav-create')));
    await tap(find.byKey(const Key('submit-report')));
    expect(find.text('Ciri-ciri barang minimal 10 karakter.'), findsOneWidget);
    await shot('android-08-validasi-laporan');
    await tester.ensureVisible(find.byKey(const Key('report-title')));
    await tester.enterText(
      find.byKey(const Key('report-title')),
      'Payung hijau',
    );
    await tester.ensureVisible(find.byKey(const Key('report-location')));
    await tester.enterText(
      find.byKey(const Key('report-location')),
      'Perpustakaan sekolah',
    );
    await tester.ensureVisible(find.byKey(const Key('report-description')));
    await tester.enterText(
      find.byKey(const Key('report-description')),
      'Payung lipat hijau dengan gagang kayu dan tali hitam.',
    );
    await tester.ensureVisible(find.byKey(const Key('report-title')));
    await shot('android-09-formulir');
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
    ]);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    expect(store.draft['title'], 'Payung hijau');
    await shot('android-10-landscape');
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    await tap(find.byKey(const Key('nav-home')));
    await tap(find.byKey(const Key('nav-create')));
    expect(find.text('Payung hijau'), findsOneWidget);
    await tap(find.byKey(const Key('submit-report')));
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await shot('android-11-laporan-saya');
    await tap(find.text('Payung hijau'));
    await tap(find.text('Tandai selesai'));
    await tap(find.text('Batal'));
    expect(store.items.first.resolved, isFalse);
    await tap(find.text('Tandai selesai'));
    await tap(find.text('Ya, sudah selesai'));
    expect(store.items.first.resolved, isTrue);
    await shot('android-12-selesai');
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tap(find.byTooltip('Pengaturan'));
    await tap(find.byType(Switch));
    await shot('android-13-pengaturan-gelap');
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tap(find.byKey(const Key('nav-home')));
    await shot('android-14-beranda-gelap');
    await store.flush();
    final reopened = AppStore();
    await reopened.load();
    expect(reopened.items.first.title, 'Payung hijau');
    expect(reopened.items.first.resolved, isTrue);
    expect(reopened.savedIds, contains('LF-002'));
    expect(reopened.userName, 'Fawwaz Khairiy Wahid');
    expect(reopened.dark, isTrue);
    expect(tester.takeException(), isNull);
    await SystemChrome.setPreferredOrientations([]);
  });
}
