import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/carousel.dart';
import '../widgets/more.dart';
import 'detail_screen.dart';
import 'detail/disarankan.dart';
import 'detail/langganan.dart';
import 'detail/terdekat.dart';
import 'post_screen.dart';
import 'error/login.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        automaticallyImplyLeading: false,
        title: const Text(
          'WONGIWAK',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.w800,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              child: CircleAvatar(
                radius: 19,
                backgroundColor: const Color(0xFFEEF3FF),
                child: const Icon(
                  Icons.person_rounded,
                  color: Color(0xFF6C8EF5),
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6C8EF5),
        elevation: 4,
        onPressed: () {
          if (FirebaseAuth.instance.currentUser == null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginErrorScreen()),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PostScreen(isLogin: true)),
            );
          }
        },
        child: const Icon(Icons.add_rounded, size: 26),
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
                images: [
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: searchController,
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.toLowerCase();
                    });
                  },
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1A1A2E),
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Cari ikan, kategori, atau lokasi...',
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: Color(0xFF9E9E9E),
                      size: 20,
                    ),
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      color: Color(0xFFBDBDBD),
                      fontSize: 14,
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
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
                              ? const Color(0xFF6C8EF5)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: active
                              ? [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF6C8EF5,
                                    ).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : [],
                          border: Border.all(
                            color: active
                                ? const Color(0xFF6C8EF5)
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            color: active
                                ? Colors.white
                                : const Color(0xFF6B6B80),
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
              const SizedBox(height: 22),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('ikan')
                    .orderBy('created_at', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(
                          color: Color(0xFF6C8EF5),
                        ),
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Text(
                          'Belum ada data ikan',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }

                  final allData = snapshot.data!.docs;

                  final filteredData = allData.where((doc) {
                    final ikan = doc.data() as Map<String, dynamic>;
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
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Text(
                          'Tidak ditemukan ikan yang cocok',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }

                  // Section Disarankan: 2 item pertama
                  final disarankanItems = filteredData.length >= 2
                      ? filteredData.sublist(0, 2)
                      : filteredData;

                  // Section Terdekat: item ke-5 dan seterusnya
                  final terdekatItems = filteredData.length > 4
                      ? filteredData.sublist(4)
                      : <QueryDocumentSnapshot>[];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MoreSectionWidget(
                        title: 'Disarankan',
                        // Kirim semua filteredData agar "Lihat Semua" punya konteks penuh
                        items: filteredData,
                        detailBuilder: (id) => DetailScreen(ikanId: id),
                        onSeeMore: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                DisarankanScreen(items: filteredData),
                          ),
                        ),
                      ),

                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(FirebaseAuth.instance.currentUser!.uid)
                            .collection('langganan')
                            .snapshots(),
                        builder: (context, subSnapshot) {
                          if (subSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF6C8EF5),
                                ),
                              ),
                            );
                          }

                          if (!subSnapshot.hasData ||
                              subSnapshot.data!.docs.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          final subscribedUsernames = subSnapshot.data!.docs
                              .map((doc) => doc['username'] as String)
                              .toList();

                          final shouldLimitItems =
                              subscribedUsernames.length > 4;
                          final itemsPerUser = shouldLimitItems ? 2 : 999;

                          final Map<String, List<QueryDocumentSnapshot>>
                          productsByUser = {};
                          for (final username in subscribedUsernames) {
                            productsByUser[username] = filteredData
                                .where((doc) {
                                  final ikan =
                                      doc.data() as Map<String, dynamic>;
                                  return ikan['username']?.toString() ==
                                      username;
                                })
                                .take(itemsPerUser)
                                .toList();
                          }

                          final subscribedProducts = productsByUser.values
                              .expand((list) => list)
                              .toList();

                          if (subscribedProducts.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          return MoreSectionWidget(
                            title: 'Langganan',
                            items: subscribedProducts,
                            detailBuilder: (id) => DetailScreen(ikanId: id),
                            onSeeMore: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    LanggananScreen(items: subscribedProducts),
                              ),
                            ),
                          );
                        },
                      ),

                      if (terdekatItems.isNotEmpty)
                        MoreSectionWidget(
                          title: 'Terdekat',
                          items: terdekatItems,
                          detailBuilder: (id) => DetailScreen(ikanId: id),
                          onSeeMore: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  TerdekatScreen(items: terdekatItems),
                            ),
                          ),
                        ),

                      const SizedBox(height: 80),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
