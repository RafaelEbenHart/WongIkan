import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:wongiwak/screens/sign_in_screen.dart';
import '../widgets/carousel.dart';
import 'detail_screen.dart';

class GuestScreen extends StatefulWidget {
  const GuestScreen({super.key});

  @override
  State<GuestScreen> createState() => _GuestScreenState();
}

class _GuestScreenState extends State<GuestScreen> {
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  final List<String> kategoriOptions = [
    'Semua',
    'Ikan Air Tawar',
    'Ikan Laut',
    'Ikan Hias',
    'Udang',
    'Kepiting',
    'Lobster',
    'Lainnya',
  ];
  String selectedCategory = 'Semua';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _tampilDialogLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SignInScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'WONGIKAN',
          style: TextStyle(
            color: colorScheme.onBackground,
            fontWeight: FontWeight.w800,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: _tampilDialogLogin,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  'Login',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              CarouselWidget(
                images: const [
                  'assets/images/Carousel1.png',
                  'assets/images/Carousel2.png',
                  'assets/images/Carousel3.png',
                ],
                height: 180,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: searchController,
                  onChanged: (value) =>
                      setState(() => searchQuery = value.toLowerCase()),
                  style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Cari ikan, kategori, atau lokasi...',
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: colorScheme.onSurface.withOpacity(0.4),
                      size: 20,
                    ),
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.35),
                      fontSize: 14,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: kategoriOptions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final category = kategoriOptions[index];
                    final bool active = category == selectedCategory;
                    return GestureDetector(
                      onTap: () => setState(() => selectedCategory = category),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? colorScheme.primary
                              : colorScheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: active
                              ? [
                                  BoxShadow(
                                    color: colorScheme.primary.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : [],
                          border: Border.all(
                            color: active
                                ? colorScheme.primary
                                : colorScheme.outline.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            color: active
                                ? colorScheme.onPrimary
                                : colorScheme.onSurface.withOpacity(0.7),
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Disarankan',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onBackground,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('ikan')
                    .orderBy('created_at', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Text(
                          'Terjadi kesalahan saat memuat data',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: CircularProgressIndicator(
                          color: colorScheme.primary,
                        ),
                      ),
                    );
                  }

                  final allData = snapshot.data?.docs ?? [];

                  if (allData.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Text(
                          'Belum ada data ikan',
                          style: TextStyle(
                            color: colorScheme.onBackground.withOpacity(0.5),
                          ),
                        ),
                      ),
                    );
                  }

                  final filteredData = allData.where((doc) {
                    final ikan = doc.data() as Map<String, dynamic>? ?? {};
                    final nama = (ikan['nama']?.toString() ?? '').toLowerCase();
                    final kategori = (ikan['kategori']?.toString() ?? '')
                        .toLowerCase();
                    final lokasi = (ikan['lokasi']?.toString() ?? '')
                        .toLowerCase();
                    final matchesSearch =
                        searchQuery.isEmpty ||
                        nama.contains(searchQuery) ||
                        kategori.contains(searchQuery) ||
                        lokasi.contains(searchQuery);
                    final matchesCategory =
                        selectedCategory == 'Semua' ||
                        kategori == selectedCategory.toLowerCase();
                    return matchesSearch && matchesCategory;
                  }).toList();

                  if (filteredData.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Text(
                          'Tidak ditemukan ikan yang cocok',
                          style: TextStyle(
                            color: colorScheme.onBackground.withOpacity(0.5),
                          ),
                        ),
                      ),
                    );
                  }

                  final screenWidth = MediaQuery.of(context).size.width;
                  final cardWidth = (screenWidth - 32 - 10) / 2;

                  return Wrap(
                    spacing: 10,
                    runSpacing: 12,
                    children: filteredData.map((doc) {
                      final ikan = doc.data() as Map<String, dynamic>? ?? {};
                      return SizedBox(
                        width: cardWidth,
                        child: _GuestFishCard(doc: doc, ikan: ikan),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuestFishCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final Map<String, dynamic> ikan;

  const _GuestFishCard({required this.doc, required this.ikan});

  Widget _placeholder(ColorScheme colorScheme) => Container(
    color: colorScheme.primaryContainer.withOpacity(0.3),
    child: Center(
      child: Icon(Icons.set_meal_rounded, size: 38, color: colorScheme.primary),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final lokasiText = ikan['lokasi']?.toString() ?? '-';
    final harga = ikan['harga']?.toString() ?? '0';
    final nama = ikan['nama']?.toString() ?? 'Tanpa Nama';
    final gambarString = ikan['gambar']?.toString() ?? '';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailScreen(ikanId: doc.id)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : colorScheme.primary.withOpacity(0.10),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 112,
                child: gambarString.isNotEmpty
                    ? Image.memory(
                        base64Decode(gambarString),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(colorScheme),
                      )
                    : _placeholder(colorScheme),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nama,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 11,
                        color: colorScheme.onSurface.withOpacity(0.45),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          lokasiText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.onSurface.withOpacity(0.45),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Rp $harga',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
