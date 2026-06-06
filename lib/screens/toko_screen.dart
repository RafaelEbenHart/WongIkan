import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wongiwak/screens/detail_screen.dart';
import 'package:wongiwak/screens/sign_in_screen.dart';

class TokoScreen extends StatefulWidget {
  final String username;
  final String alamat;

  const TokoScreen({super.key, required this.username, required this.alamat});

  @override
  State<TokoScreen> createState() => _TokoScreenState();
}

class _TokoScreenState extends State<TokoScreen> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  bool _isSubscribed = false;
  bool _isLoadingSub = false;

  @override
  void initState() {
    super.initState();
    _cekSubscription();
  }

  Future<void> _cekSubscription() async {
    final user = auth.currentUser;
    if (user == null) return;

    final doc = await firestore
        .collection('users')
        .doc(user.uid)
        .collection('langganan')
        .doc(widget.username)
        .get();

    if (mounted) setState(() => _isSubscribed = doc.exists);
  }

  Future<void> _toggleSubscription() async {
    final user = auth.currentUser;
    if (user == null) {
      _tampilDialogLogin();
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
        await ref.delete();
        setState(() => _isSubscribed = false);
      } else {
        await ref.set({
          'username': widget.username,
          'alamat': widget.alamat,
          'created_at': FieldValue.serverTimestamp(),
        });
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
    return Scaffold(
      backgroundColor: const Color(0xffF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Toko",
          style: TextStyle(
            color: Colors.black,
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.blue.shade100,
                    child: const Icon(
                      Icons.person,
                      color: Colors.blue,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.username,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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
                                style: const TextStyle(
                                  color: Colors.black54,
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
                    .where('username', isEqualTo: widget.username)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final produk = snapshot.data?.docs ?? [];

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            const Text(
                              "Semua Produk",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
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
                                "${produk.length} produk",
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
                        child: produk.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.storefront_outlined,
                                      size: 64,
                                      color: Colors.grey.shade300,
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      "Belum ada produk",
                                      style: TextStyle(
                                        color: Colors.black45,
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
                                itemCount: produk.length,
                                itemBuilder: (context, index) {
                                  final item =
                                      produk[index].data()
                                          as Map<String, dynamic>;
                                  final ikanId = produk[index].id;
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
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(
                                              0.05,
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
                                              color: Colors.blue.shade50,
                                              child:
                                                  gambar.toString().isNotEmpty
                                                  ? Image.memory(
                                                      base64Decode(gambar),
                                                      fit: BoxFit.cover,
                                                    )
                                                  : Icon(
                                                      Icons.image,
                                                      size: 40,
                                                      color:
                                                          Colors.blue.shade200,
                                                    ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  nama,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
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
