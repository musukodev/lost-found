import 'package:flutter/material.dart';

import 'store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = AppStore();
  runApp(LostFoundApp(store: store));
  await store.load();
}

class LostFoundApp extends StatelessWidget {
  const LostFoundApp({super.key, required this.store});
  final AppStore store;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) => MaterialApp(
      title: 'Lost & Found Sekolah',
      debugShowCheckedModeBanner: false,
      theme: schoolTheme(Brightness.light),
      darkTheme: schoolTheme(Brightness.dark),
      themeMode: store.dark ? ThemeMode.dark : ThemeMode.light,
      home: RootScreen(store: store),
    ),
  );
}

ThemeData schoolTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: const Color(0xff174b3b),
        brightness: brightness,
      ).copyWith(
        primary: dark ? const Color(0xff9dd8bc) : const Color(0xff174b3b),
        onPrimary: dark ? const Color(0xff102e23) : Colors.white,
        surface: dark ? const Color(0xff14231e) : const Color(0xfff7f6f0),
        onSurface: dark ? const Color(0xffedf3ed) : const Color(0xff192c26),
        onSurfaceVariant: dark
            ? const Color(0xffbed0c5)
            : const Color(0xff4c6055),
        error: dark ? const Color(0xffffb49e) : const Color(0xff963d27),
      );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'SchoolSans',
    scaffoldBackgroundColor: scheme.surface,
    visualDensity: VisualDensity.standard,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xff20372d) : Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.all(16),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        textStyle: const TextStyle(
          fontFamily: 'SchoolSans',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

class RootScreen extends StatelessWidget {
  const RootScreen({super.key, required this.store});
  final AppStore store;
  @override
  Widget build(BuildContext context) {
    if (store.loading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 24),
              Text('Memuat papan barang sekolah...'),
            ],
          ),
        ),
      );
    }
    if (store.error != null && store.items.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: PageBody(
            children: [
              const SizedBox(height: 48),
              const PageHeading(
                'Data lokal belum terbaca',
                'Laporan tidak dihapus otomatis.',
              ),
              Text(store.error!),
              FilledButton(
                onPressed: store.load,
                child: const Text('Coba lagi'),
              ),
              OutlinedButton(
                onPressed: store.resetDemo,
                child: const Text('Pulihkan data demo'),
              ),
            ],
          ),
        ),
      );
    }
    if (store.userName.isEmpty) {
      return WelcomeScreen(store: store);
    }
    return HomeShell(store: store);
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.store});
  final AppStore store;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: PageBody(
        maxWidth: 600,
        children: [
          const SizedBox(height: 48),
          Text('Lost & Found', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 40),
          Text(
            'Barang tertinggal.\nBisa kembali.',
            style: Theme.of(context).textTheme.displaySmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          const Text(
            'Papan barang hilang dan temuan untuk warga sekolah.',
            style: TextStyle(fontSize: 18, height: 1.6),
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'Cari barang berdasarkan ciri dan lokasi. Laporkan temuan supaya pemiliknya bisa mencari.',
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => LoginScreen(store: store),
              ),
            ),
            child: const Text('Masuk ke papan barang'),
          ),
          const SizedBox(height: 16),
          const DemoNote(),
        ],
      ),
    ),
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.store});
  final AppStore store;
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final form = GlobalKey<FormState>();
  bool attempted = false;
  final name = TextEditingController(), kelas = TextEditingController();
  @override
  void dispose() {
    name.dispose();
    kelas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Masuk demo')),
    body: PageBody(
      maxWidth: 600,
      children: [
        const PageHeading(
          'Kenalkan dirimu',
          'Nama dan kelas dipakai sebagai identitas laporan lokal.',
        ),
        const DemoNote(),
        const SizedBox(height: 24),
        Form(
          key: form,
          autovalidateMode: attempted
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const Key('login-name'),
                controller: name,
                decoration: const InputDecoration(labelText: 'Nama siswa'),
                maxLength: 60,
                textInputAction: TextInputAction.next,
                validator: (v) => (v ?? '').trim().length < 3
                    ? 'Nama minimal 3 karakter.'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('login-class'),
                controller: kelas,
                maxLength: 30,
                decoration: const InputDecoration(
                  labelText: 'Kelas',
                  hintText: 'Contoh: XI IPA 1',
                ),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Kelas wajib diisi.' : null,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  setState(() => attempted = true);
                  if (form.currentState!.validate()) {
                    widget.store.login(name.text, kelas.text);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Masuk demo'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Tidak memakai password atau akun sekolah. Identitas demo ini bukan autentikasi sungguhan.',
        ),
      ],
    ),
  );
}

class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.store});
  final AppStore store;
  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(store: store),
      BrowseScreen(store: store),
      ReportForm(store: store),
      MyReportsScreen(store: store),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lost & Found'),
        actions: [
          IconButton(
            tooltip: 'Barang tersimpan',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => SavedScreen(store: store),
              ),
            ),
            icon: const Icon(Icons.bookmark_outline),
          ),
          IconButton(
            tooltip: 'Pengaturan',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => SettingsScreen(store: store),
              ),
            ),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          if (store.error != null)
            MaterialBanner(
              content: Text(store.error!),
              actions: [
                TextButton(
                  onPressed: store.retrySave,
                  child: const Text('Simpan lagi'),
                ),
              ],
            ),
          Expanded(child: pages[store.tab]),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: store.tab,
        onDestinationSelected: store.setTab,
        destinations: const [
          NavigationDestination(
            key: Key('nav-home'),
            icon: Icon(Icons.dashboard_outlined),
            label: 'Beranda',
          ),
          NavigationDestination(
            key: Key('nav-search'),
            icon: Icon(Icons.search),
            label: 'Jelajah',
          ),
          NavigationDestination(
            key: Key('nav-create'),
            icon: Icon(Icons.add_box_outlined),
            label: 'Lapor',
          ),
          NavigationDestination(
            key: Key('nav-mine'),
            icon: Icon(Icons.assignment_outlined),
            label: 'Milik saya',
          ),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.store});
  final AppStore store;
  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      Text(
        'Halo, ${store.userName}',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 8),
      const PageHeading(
        'Papan barang sekolah',
        'Kehilangan sesuatu? Mulai dari lokasi terakhir kamu melihatnya.',
      ),
      FilledButton.icon(
        onPressed: () => store.setTab(2),
        icon: const Icon(Icons.add),
        label: const Text('Buat laporan'),
      ),
      const SizedBox(height: 16),
      const DemoNote(),
      const SizedBox(height: 24),
      Row(
        children: [
          Expanded(
            child: Text(
              'Laporan terbaru',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          TextButton(
            onPressed: () => store.setTab(1),
            child: const Text('Lihat semua'),
          ),
        ],
      ),
      const SizedBox(height: 8),
      ...store.items.take(4).map((i) => ItemTile(item: i, store: store)),
      const SizedBox(height: 24),
      const Text(
        'Saat mengambil barang',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 8),
      const Text(
        'Cocokkan ciri-ciri barang bersama petugas sekolah. Jangan unggah nomor identitas atau informasi pribadi yang sensitif.',
      ),
    ],
  );
}

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key, required this.store});
  final AppStore store;
  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  AppStore get store => widget.store;
  late final TextEditingController search;
  @override
  void initState() {
    super.initState();
    search = TextEditingController(text: store.query);
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      const PageHeading(
        'Jelajah barang',
        'Cari nama barang, ciri-ciri, atau lokasi di sekolah.',
      ),
      TextFormField(
        key: const Key('search-field'),
        controller: search,
        onChanged: (v) => store.filter(query: v),
        decoration: const InputDecoration(
          labelText: 'Cari barang atau lokasi',
          prefixIcon: Icon(Icons.search),
        ),
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: reportTypes
            .map(
              (v) => ChoiceChip(
                label: Text(v),
                selected: store.typeFilter == v,
                onSelected: (_) => store.filter(type: v),
                materialTapTargetSize: MaterialTapTargetSize.padded,
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        key: ValueKey(store.categoryFilter),
        initialValue: store.categoryFilter,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Kategori'),
        items: categories
            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
            .toList(),
        onChanged: (v) => store.filter(category: v),
      ),
      const SizedBox(height: 24),
      Text(
        '${store.filtered.length} laporan dalam data demo',
        style: Theme.of(context).textTheme.labelLarge,
      ),
      const SizedBox(height: 12),
      if (store.filtered.isEmpty)
        EmptyMessage(
          title: 'Barang belum cocok',
          message:
              'Coba kata lain atau hapus filter untuk melihat seluruh laporan.',
          action: 'Hapus filter',
          onPressed: () {
            search.clear();
            store.filter(query: '', type: 'Semua', category: 'Semua');
          },
        )
      else
        ...store.filtered.map((i) => ItemTile(item: i, store: store)),
    ],
  );
}

IconData categoryIcon(String category) => switch (category) {
  'Elektronik' => Icons.calculate_outlined,
  'Buku' => Icons.menu_book_outlined,
  'Aksesori' => Icons.key_outlined,
  _ => Icons.backpack_outlined,
};

class ItemTile extends StatelessWidget {
  const ItemTile({super.key, required this.item, required this.store});
  final ItemReport item;
  final AppStore store;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => DetailScreen(id: item.id, store: store),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Icon(categoryIcon(item.category), size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusLabel(item: item),
                    const SizedBox(height: 8),
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(item.location),
                    const SizedBox(height: 4),
                    Text(
                      '${item.date} · ${item.category}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    ),
  );
}

class StatusLabel extends StatelessWidget {
  const StatusLabel({super.key, required this.item});
  final ItemReport item;
  @override
  Widget build(BuildContext context) => Text(
    item.resolved ? 'Selesai' : item.type,
    style: TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 14,
      color: item.type == 'Hilang' && !item.resolved
          ? Theme.of(context).colorScheme.error
          : Theme.of(context).colorScheme.primary,
    ),
  );
}

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.id, required this.store});
  final String id;
  final AppStore store;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final item = store.item(id);
      return Scaffold(
        appBar: AppBar(title: const Text('Detail barang')),
        body: PageBody(
          maxWidth: 700,
          children: [
            Text(item.id, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 12),
            StatusLabel(item: item),
            const SizedBox(height: 12),
            PageHeading(item.title, item.location),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              item.description,
              style: const TextStyle(fontSize: 18, height: 1.6),
            ),
            const SizedBox(height: 24),
            InfoLine('Tanggal kejadian', item.date),
            InfoLine('Kategori', item.category),
            InfoLine('Pelapor', item.owner),
            InfoLine('Kelas', item.schoolClass),
            const SizedBox(height: 16),
            const DemoNote(),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              key: const Key('save-item'),
              onPressed: () => store.toggleSaved(id),
              icon: Icon(
                store.savedIds.contains(id)
                    ? Icons.bookmark
                    : Icons.bookmark_outline,
              ),
              label: Text(
                store.savedIds.contains(id)
                    ? 'Hapus dari tersimpan'
                    : 'Simpan barang',
              ),
            ),
            const SizedBox(height: 12),
            if (store.isMine(item) && !item.resolved)
              FilledButton(
                onPressed: () async {
                  final yes = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Selesaikan laporan?'),
                      content: const Text(
                        'Gunakan setelah barang kembali kepada pemiliknya. Status tersimpan sebagai selesai.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Batal'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Ya, sudah selesai'),
                        ),
                      ],
                    ),
                  );
                  if (yes == true) {
                    await store.resolve(id);
                  }
                },
                child: const Text('Tandai selesai'),
              ),
            if (!store.isMine(item))
              OutlinedButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Cocokkan dengan petugas'),
                    content: Text(
                      'Catat nomor ${item.id} dan sebutkan ciri khusus barang kepada petugas sekolah. Data ini simulasi; tidak ada pesan yang dikirim.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Mengerti'),
                      ),
                    ],
                  ),
                ),
                child: const Text('Cara mengambil barang'),
              ),
          ],
        ),
      );
    },
  );
}

class ReportForm extends StatefulWidget {
  const ReportForm({super.key, required this.store});
  final AppStore store;
  @override
  State<ReportForm> createState() => _ReportFormState();
}

class _ReportFormState extends State<ReportForm> {
  final form = GlobalKey<FormState>();
  bool attempted = false;
  String? problem;
  bool submitting = false;
  @override
  Widget build(BuildContext context) => PageBody(
    maxWidth: 600,
    children: [
      const PageHeading(
        'Buat laporan',
        'Tuliskan ciri yang membantu pemilik mengenali barangnya.',
      ),
      const Text('Draf tersimpan otomatis di perangkat ini.'),
      const SizedBox(height: 24),
      Form(
        key: form,
        autovalidateMode: attempted
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              initialValue: widget.store.draft['type'],
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Jenis laporan'),
              items: reportTypes
                  .skip(1)
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: (v) => widget.store.updateDraft('type', v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('report-title'),
              initialValue: widget.store.draft['title'],
              maxLength: 80,
              decoration: const InputDecoration(labelText: 'Nama barang'),
              onChanged: (v) => widget.store.updateDraft('title', v),
              validator: (v) => (v ?? '').trim().length < 3
                  ? 'Nama barang minimal 3 karakter.'
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: widget.store.draft['category'],
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Kategori barang'),
              items: categories
                  .skip(1)
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: (v) => widget.store.updateDraft('category', v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('report-location'),
              initialValue: widget.store.draft['location'],
              maxLength: 100,
              decoration: const InputDecoration(
                labelText: 'Lokasi kejadian',
                hintText: 'Contoh: perpustakaan atau kantin',
              ),
              onChanged: (v) => widget.store.updateDraft('location', v),
              validator: (v) => (v ?? '').trim().length < 3
                  ? 'Lokasi minimal 3 karakter.'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('report-date'),
              initialValue: widget.store.draft['date'],
              keyboardType: TextInputType.datetime,
              decoration: const InputDecoration(
                labelText: 'Tanggal kejadian',
                helperText: 'Format YYYY-MM-DD. Tidak boleh di masa depan.',
              ),
              onChanged: (v) => widget.store.updateDraft('date', v),
              validator: (v) {
                final d = DateTime.tryParse(v ?? '');
                return d == null ||
                        d.toIso8601String().substring(0, 10) != v ||
                        d.isAfter(DateTime.now())
                    ? 'Masukkan tanggal valid, paling lambat hari ini.'
                    : null;
              },
            ),
            const SizedBox(height: 24),
            TextFormField(
              key: const Key('report-description'),
              initialValue: widget.store.draft['description'],
              maxLength: 500,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Ciri-ciri barang',
                alignLabelWithHint: true,
              ),
              onChanged: (v) => widget.store.updateDraft('description', v),
              validator: (v) => (v ?? '').trim().length < 10
                  ? 'Ciri-ciri barang minimal 10 karakter.'
                  : null,
            ),
            const SizedBox(height: 16),
            if (problem != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  problem!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            FilledButton(
              key: const Key('submit-report'),
              onPressed: submitting
                  ? null
                  : () async {
                      setState(() => attempted = true);
                      if (!form.currentState!.validate()) {
                        return;
                      }
                      setState(() => submitting = true);
                      final id = await widget.store.submitDraft();
                      if (!context.mounted) {
                        return;
                      }
                      if (id == null) {
                        setState(() {
                          problem =
                              widget.store.validateDraft() ??
                              'Masuk demo terlebih dahulu.';
                          submitting = false;
                        });
                        return;
                      }
                      widget.store.setTab(3);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            widget.store.error == null
                                ? 'Laporan disimpan di perangkat ini.'
                                : 'Laporan ada di memori. Penyimpanan lokal perlu dicoba lagi.',
                          ),
                        ),
                      );
                    },
              child: Text(
                submitting ? 'Menyimpan laporan...' : 'Simpan laporan',
              ),
            ),
            const SizedBox(height: 16),
            const DemoNote(),
          ],
        ),
      ),
    ],
  );
}

class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key, required this.store});
  final AppStore store;
  @override
  Widget build(BuildContext context) {
    final mine = store.items.where(store.isMine).toList();
    return PageBody(
      children: [
        const PageHeading(
          'Laporan saya',
          'Pantau laporan yang kamu buat dan tandai setelah barang kembali.',
        ),
        if (mine.isEmpty)
          EmptyMessage(
            title: 'Belum ada laporanmu',
            message: 'Laporkan barang hilang atau temuan di sekitar sekolah.',
            action: 'Buat laporan',
            onPressed: () => store.setTab(2),
          )
        else
          ...mine.map((i) => ItemTile(item: i, store: store)),
      ],
    );
  }
}

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key, required this.store});
  final AppStore store;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final saved = store.items
          .where((i) => store.savedIds.contains(i.id))
          .toList();
      return Scaffold(
        appBar: AppBar(title: const Text('Barang tersimpan')),
        body: PageBody(
          children: [
            const PageHeading(
              'Periksa lagi nanti',
              'Daftar barang yang kamu simpan di perangkat ini.',
            ),
            if (saved.isEmpty)
              const EmptyMessage(
                title: 'Belum ada barang tersimpan',
                message: 'Buka detail barang, lalu pilih Simpan barang.',
              )
            else
              ...saved.map((i) => ItemTile(item: i, store: store)),
          ],
        ),
      );
    },
  );
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.store});
  final AppStore store;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) => Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: PageBody(
        maxWidth: 600,
        children: [
          PageHeading(store.userName, store.schoolClass),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Tema gelap'),
            subtitle: const Text('Disimpan di perangkat ini.'),
            value: store.dark,
            onChanged: store.setDark,
          ),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'Tentang aplikasi',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Lost & Found Sekolah membantu latihan pelaporan barang hilang dan temuan. Seluruh laporan awal adalah dummy. Tidak terhubung ke server, akun sekolah, atau layanan pesan.',
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () async {
              final yes = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Pulihkan data demo?'),
                  content: const Text(
                    'Laporan buatanmu, draf, dan simpanan akan dihapus dari perangkat ini. Identitas demo tetap dipertahankan.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Batal'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Pulihkan data'),
                    ),
                  ],
                ),
              );
              if (yes == true) {
                await store.resetDemo();
              }
            },
            child: const Text('Pulihkan data demo'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              store.logout();
              Navigator.popUntil(context, (r) => r.isFirst);
            },
            child: const Text('Keluar demo'),
          ),
        ],
      ),
    ),
  );
}

class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children, this.maxWidth = 900});
  final List<Widget> children;
  final double maxWidth;
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    ),
  );
}

class PageHeading extends StatelessWidget {
  const PageHeading(this.title, this.subtitle, {super.key});
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 12),
        Text(subtitle, style: const TextStyle(fontSize: 16, height: 1.6)),
      ],
    ),
  );
}

class DemoNote extends StatelessWidget {
  const DemoNote({super.key});
  @override
  Widget build(BuildContext context) => Text(
    'Mode demo · Data dummy · Tersimpan lokal',
    style: TextStyle(
      fontSize: 13,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );
}

class InfoLine extends StatelessWidget {
  const InfoLine(this.label, this.value, {super.key});
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16)),
      ],
    ),
  );
}

class EmptyMessage extends StatelessWidget {
  const EmptyMessage({
    super.key,
    required this.title,
    required this.message,
    this.action,
    this.onPressed,
  });
  final String title, message;
  final String? action;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Text(message),
        if (action != null) ...[
          const SizedBox(height: 24),
          OutlinedButton(onPressed: onPressed, child: Text(action!)),
        ],
      ],
    ),
  );
}
