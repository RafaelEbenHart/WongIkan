import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wongiwak/screens/sign_in_screen.dart';
import 'package:wongiwak/widgets/commentTrigger.dart';

class DetailScreen extends StatefulWidget {
  final String ikanId;

  const DetailScreen({super.key, required this.ikanId});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  String formatRupiah(dynamic harga) {
    final number = int.tryParse(harga.toString()) ?? 0;
    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return format.format(number);
  }

  Future<void> openMap(double lat, double long) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$long',
    );
    final success = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak bisa membuka Google Maps')),
      );
    }
  }

  void sharePost(Map<String, dynamic> data) {
    Share.share(
      '🐟 ${data['nama']}\n'
      '💰 ${formatRupiah(data['harga'])} / Kg\n'
      '📍 ${data['lokasi']}',
    );
  }

  void _bukaKomentar(String ikanId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => KomentarSheet(ikanId: ikanId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F5F5),

      body: StreamBuilder<DocumentSnapshot>(
        stream: firestore.collection('ikan').doc(widget.ikanId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Data tidak ditemukan"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final nama = data['nama'] ?? '';
          final harga = data['harga'] ?? '';
          final kategori = data['kategori'] ?? '';
          final username = data['username'] ?? '';
          final alamat = data['alamat'] ?? '';
          final gambar = data['gambar'] ?? '';
          final deskripsi = data['deskripsi'] ?? '';

          final latitude = data['latitude'];
          final longitude = data['longitude'];
          final lokasiValue = data['lokasi']?.toString() ?? '';
          final lokasiText = lokasiValue.isNotEmpty
              ? lokasiValue
              : (latitude != null && longitude != null
                    ? '${(latitude is num ? latitude.toDouble() : double.tryParse(latitude.toString()) ?? 0).toStringAsFixed(5)}, ${(longitude is num ? longitude.toDouble() : double.tryParse(longitude.toString()) ?? 0).toStringAsFixed(5)}'
                    : 'Lokasi tidak tersedia');

          final createdAt = data['created_at'] != null
              ? (data['created_at'] as Timestamp).toDate()
              : DateTime.now();

          return CommentTrigger(
            onSwipeUp: () => _bukaKomentar(widget.ikanId),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new,
                                size: 18,
                              ),
                            ),
                          ),
                          const Text(
                            "Detail",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => sharePost(data),
                            child: Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.share),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      height: 260,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: gambar.toString().isNotEmpty
                          ? Image.memory(
                              base64Decode(gambar),
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.image, size: 80),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GestureDetector(
                        onTap: () => _bukaKomentar(widget.ikanId),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: StreamBuilder<QuerySnapshot>(
                            stream: firestore
                                .collection('ikan')
                                .doc(widget.ikanId)
                                .collection('komentar')
                                .snapshots(),
                            builder: (context, snap) {
                              final count = snap.hasData
                                  ? snap.data!.docs.length
                                  : 0;
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.comment_outlined, size: 20),
                                  const SizedBox(width: 6),
                                  Text("$count Komentar"),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nama,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            kategori,
                            style: const TextStyle(
                              color: Color(0xFF6C8EF5),
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "${formatRupiah(harga)} / Kg",
                            style: const TextStyle(
                              color: Color(0xff6C8EF5),
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Info Penjual",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: Colors.blue.shade100,
                                      child: const Icon(
                                        Icons.person,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            username,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            alamat,
                                            style: const TextStyle(
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Lokasi",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        lokasiText,
                                        style: const TextStyle(
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xff6C8EF5),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    onPressed:
                                        (latitude != null && longitude != null)
                                        ? () {
                                            double lat = (latitude is num)
                                                ? latitude.toDouble()
                                                : double.tryParse(
                                                        latitude.toString(),
                                                      ) ??
                                                      0;
                                            double lng = (longitude is num)
                                                ? longitude.toDouble()
                                                : double.tryParse(
                                                        longitude.toString(),
                                                      ) ??
                                                      0;
                                            if (lat != 0 && lng != 0) {
                                              openMap(lat, lng);
                                            } else {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Koordinat lokasi tidak valid',
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        : null,
                                    icon: const Icon(
                                      Icons.map,
                                      color: Colors.white,
                                    ),
                                    label: const Text(
                                      "Buka Google Maps",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (deskripsi.toString().isNotEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Deskripsi",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(deskripsi),
                                ],
                              ),
                            ),
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Diposting",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  DateFormat(
                                    'dd MMM yyyy • HH:mm',
                                  ).format(createdAt),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 60),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class KomentarSheet extends StatefulWidget {
  final String ikanId;

  const KomentarSheet({super.key, required this.ikanId});

  @override
  State<KomentarSheet> createState() => _KomentarSheetState();
}

class _KomentarSheetState extends State<KomentarSheet> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  final TextEditingController _komentarController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _komentarController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _sudahLogin => auth.currentUser != null;

  Future<String> _getUsername() async {
    final user = auth.currentUser;
    if (user == null) return 'Pengguna';
    try {
      final doc = await firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['username'] ?? 'Pengguna';
      }
    } catch (_) {}
    return 'Pengguna';
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
          "Kamu harus login atau membuat akun terlebih dahulu untuk bisa mengirim komentar.",
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

  Future<void> _kirimKomentar() async {
    final teks = _komentarController.text.trim();
    if (teks.isEmpty) return;

    if (!_sudahLogin) {
      _tampilDialogLogin();
      return;
    }

    setState(() => _isSending = true);

    try {
      final username = await _getUsername();
      await firestore
          .collection('ikan')
          .doc(widget.ikanId)
          .collection('komentar')
          .add({
            'username': username,
            'isi': teks,
            'created_at': FieldValue.serverTimestamp(),
          });
      _komentarController.clear();
      if (mounted) FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengirim: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // ── Handle ──
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Komentar",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Divider(height: 20),

                  // ── List komentar — Expanded agar tidak bisa scroll melewati batas sheet ──
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: firestore
                          .collection('ikan')
                          .doc(widget.ikanId)
                          .collection('komentar')
                          .orderBy('created_at', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final komentar = snapshot.data!.docs;

                        if (komentar.isEmpty) {
                          return const Center(
                            child: Text(
                              "Belum ada komentar.\nJadi yang pertama!",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.black45),
                            ),
                          );
                        }

                        return ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: komentar.length,
                          itemBuilder: (context, index) {
                            final k =
                                komentar[index].data() as Map<String, dynamic>;
                            final waktu = k['created_at'] != null
                                ? DateFormat('dd MMM • HH:mm').format(
                                    (k['created_at'] as Timestamp).toDate(),
                                  )
                                : '';

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Colors.blue.shade100,
                                    child: const Icon(
                                      Icons.person,
                                      color: Colors.blue,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              k['username'] ?? 'Pengguna',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              waktu,
                                              style: const TextStyle(
                                                color: Colors.black38,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(k['isi'] ?? ''),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // ── Input box — fixed di atas navbar ──
                  const Divider(height: 1),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      10,
                      16,
                      bottomInset > 0 ? 10 : 8,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _komentarController,
                            maxLines: null,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _kirimKomentar(),
                            decoration: InputDecoration(
                              hintText: _sudahLogin
                                  ? 'Tulis komentar...'
                                  : 'Login untuk berkomentar...',
                              hintStyle: const TextStyle(color: Colors.black38),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _isSending
                            ? const SizedBox(
                                width: 42,
                                height: 42,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : GestureDetector(
                                onTap: _kirimKomentar,
                                child: Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: const Color(0xff6C8EF5),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    _sudahLogin ? Icons.send : Icons.lock,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
