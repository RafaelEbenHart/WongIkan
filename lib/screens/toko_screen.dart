import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wongiwak/screens/detail_screen.dart';
import 'package:wongiwak/screens/sign_in_screen.dart';

class TokoScreen extends StatefulWidget {
  final String username;
  final String alamat;
  final String userId;

  const TokoScreen({
    super.key,
    required this.username,
    required this.alamat,
    required this.userId,
  });

  @override
  State<TokoScreen> createState() => _TokoScreenState();
}

class _TokoScreenState extends State<TokoScreen> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  bool _isSubscribed = false;
  bool _isLoadingSub = false;
  bool _isOwner = false;

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
  void initState() {
    super.initState();
    _cekOwnerDanSubscription();
  }

  Future<void> _cekOwnerDanSubscription() async {
    final user = auth.currentUser;
    if (user == null) return;

    try {
      final myDoc = await firestore.collection('users').doc(user.uid).get();
      if (myDoc.exists) {
        final myData = myDoc.data() as Map<String, dynamic>;
        final myUsername = myData['username'] ?? '';

        if (mounted) {
          setState(() {
            _isOwner = (myUsername == widget.username);
          });
        }
      }
    } catch (e) {
      debugPrint("Gagal mengecek owner: $e");
    }

    final subDoc = await firestore
        .collection('users')
        .doc(user.uid)
        .collection('langganan')
        .doc(widget.username)
        .get();

    if (mounted) setState(() => _isSubscribed = subDoc.exists);
  }

  Future<void> _toggleSubscription() async {
    final user = auth.currentUser;
    if (user == null) {
      _tampilDialogLogin();
      return;
    }

    if (_isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kamu tidak bisa mengikuti tokomu sendiri.'),
        ),
      );
      return;
    }

    setState(() => _isLoadingSub = true);

    final ref = firestore
        .collection('users')
        .doc(user.uid)
        .collection('langganan')
        .doc(widget.username);

    try {
      if (_isSubscribed) {
        // Unfollow: hapus dari following user & kurangi followers seller
        await ref.delete();

        // Kurangi followers seller
        final sellerRef = firestore
            .collection('users')
            .where('username', isEqualTo: widget.username);
        final sellerDocs = await sellerRef.get();
        if (sellerDocs.docs.isNotEmpty) {
          final sellerId = sellerDocs.docs.first.id;
          await firestore.collection('users').doc(sellerId).update({
            'followers': FieldValue.increment(-1),
          });
          // Hapus dari followers collection seller
          await firestore
              .collection('users')
              .doc(sellerId)
              .collection('followers')
              .doc(user.uid)
              .delete();
        }

        setState(() => _isSubscribed = false);
      } else {
        // Follow: tambah ke following user & tambah followers seller
        await ref.set({
          'username': widget.username,
          'alamat': widget.alamat,
          'created_at': FieldValue.serverTimestamp(),
        });

        // Tambah followers seller
        final sellerRef = firestore
            .collection('users')
            .where('username', isEqualTo: widget.username);
        final sellerDocs = await sellerRef.get();
        if (sellerDocs.docs.isNotEmpty) {
          final sellerId = sellerDocs.docs.first.id;
          await firestore.collection('users').doc(sellerId).update({
            'followers': FieldValue.increment(1),
          });
          // Tambah ke followers collection seller
          await firestore
              .collection('users')
              .doc(sellerId)
              .collection('followers')
              .doc(user.uid)
              .set({
                'uid': user.uid,
                'created_at': FieldValue.serverTimestamp(),
              });
        }

        setState(() => _isSubscribed = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengubah status langganan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingSub = false);
    }
  }

  void _tampilDialogLogin() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Perlu Login",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Kamu harus login atau membuat akun terlebih dahulu untuk berlangganan dengan penjual ini.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal", style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff6C8EF5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SignInScreen()),
              );
            },
            child: const Text("Login", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String formatRupiah(dynamic harga) {
    final number = int.tryParse(harga.toString()) ?? 0;
    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return format.format(number);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xffF5F5F5),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDark ? Colors.white : Colors.black,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Toko",
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  StreamBuilder<DocumentSnapshot>(
                    stream: firestore
                        .collection('users')
                        .doc(widget.userId)
                        .snapshots(),
                    builder: (context, userSnapshot) {
                      Uint8List? profileImageBytes;
                      if (userSnapshot.hasData && userSnapshot.data!.exists) {
                        try {
                          final userData =
                              userSnapshot.data!.data() as Map<String, dynamic>;
                          if (userData['profileImageBytes'] != null) {
                            // Handle Firestore Blob type
                            final imageData = userData['profileImageBytes'];
                            if (imageData is Blob) {
                              profileImageBytes = imageData.bytes;
                            } else if (imageData is String) {
                              profileImageBytes = base64Decode(imageData);
                            }
                          }
                        } catch (e) {
                          debugPrint('Error decoding profile image: $e');
                          profileImageBytes = null;
                        }
                      }

                      if (profileImageBytes != null &&
                          profileImageBytes.isNotEmpty) {
                        return CircleAvatar(
                          radius: 28,
                          backgroundImage: MemoryImage(profileImageBytes),
                        );
                      }

                      return CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.blue.shade100,
                        child: const Icon(
                          Icons.person,
                          color: Colors.blue,
                          size: 28,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.username,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.alamat,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (!_isOwner)
                    GestureDetector(
                      onTap: _toggleSubscription,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _isSubscribed
                              ? Colors.grey.shade200
                              : const Color(0xff6C8EF5),
                          borderRadius: BorderRadius.circular(20),
                          border: _isSubscribed
                              ? Border.all(color: Colors.grey.shade300)
                              : null,
                        ),
                        child: _isLoadingSub
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _isSubscribed ? "Diikuti" : "Ikuti",
                                style: TextStyle(
                                  color: _isSubscribed
                                      ? Colors.black87
                                      : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('ikan')
                    .where('userId', isEqualTo: widget.userId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final produk = snapshot.data?.docs ?? [];

                  final filteredProduk = produk.where((doc) {
                    final item = doc.data() as Map<String, dynamic>;
                    final kategori = (item['kategori']?.toString() ?? '')
                        .toLowerCase();
                    return selectedCategory == 'Semua' ||
                        kategori == selectedCategory.toLowerCase();
                  }).toList();

                  return Column(
                    children: [
                      SizedBox(
                        height: 42,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: kategoriOptions.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final category = kategoriOptions[index];
                            final bool active = category == selectedCategory;
                            return GestureDetector(
                              onTap: () {
                                setState(() => selectedCategory = category);
                              },
                              child: Builder(
                                builder: (ctx) {
                                  final darkBg = isDark
                                      ? const Color(0xFF1E1E1E)
                                      : Colors.white;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: active
                                          ? const Color(0xFF6C8EF5)
                                          : darkBg,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: active
                                            ? const Color(0xFF6C8EF5)
                                            : isDark
                                            ? Colors.grey.shade700
                                            : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Text(
                                      category,
                                      style: TextStyle(
                                        color: active
                                            ? Colors.white
                                            : isDark
                                            ? Colors.white
                                            : Colors.black87,
                                        fontWeight: active
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Text(
                              "Semua Produk",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xff6C8EF5,
                                ).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "${filteredProduk.length} produk",
                                style: const TextStyle(
                                  color: Color(0xff6C8EF5),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: filteredProduk.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.storefront_outlined,
                                      size: 64,
                                      color: isDark
                                          ? Colors.grey.shade600
                                          : Colors.grey.shade300,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      "Belum ada produk",
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.grey.shade400
                                            : Colors.black45,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : GridView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      childAspectRatio: 0.75,
                                    ),
                                itemCount: filteredProduk.length,
                                itemBuilder: (context, index) {
                                  final item =
                                      filteredProduk[index].data()
                                          as Map<String, dynamic>;
                                  final ikanId = filteredProduk[index].id;
                                  final nama = item['nama'] ?? '';
                                  final harga = item['harga'] ?? '';
                                  final kategori = item['kategori'] ?? '';
                                  final gambar = item['gambar'] ?? '';

                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              DetailScreen(ikanId: ikanId),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF1E1E1E)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(
                                              isDark ? 0.15 : 0.05,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      clipBehavior: Clip.hardEdge,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Container(
                                              width: double.infinity,
                                              color: isDark
                                                  ? const Color(0xFF2A2A3E)
                                                  : Colors.blue.shade50,
                                              child:
                                                  gambar.toString().isNotEmpty
                                                  ? Image.memory(
                                                      base64Decode(gambar),
                                                      fit: BoxFit.cover,
                                                    )
                                                  : Icon(
                                                      Icons.image,
                                                      size: 40,
                                                      color: isDark
                                                          ? Colors.grey.shade600
                                                          : Colors
                                                                .blue
                                                                .shade200,
                                                    ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(10),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  nama,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: isDark
                                                        ? Colors.white
                                                        : Colors.black,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  kategori,
                                                  style: const TextStyle(
                                                    color: Color(0xFF6C8EF5),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  "${formatRupiah(harga)} / Kg",
                                                  style: const TextStyle(
                                                    color: Color(0xff6C8EF5),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
