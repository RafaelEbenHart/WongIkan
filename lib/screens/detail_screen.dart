import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wongiwak/screens/sign_in_screen.dart';
import 'package:wongiwak/widgets/commentTrigger.dart';
import 'package:wongiwak/screens/toko_screen.dart';
import 'package:wongiwak/screens/perbandingan_screen.dart';

class DetailScreen extends StatefulWidget {
  final String ikanId;

  const DetailScreen({super.key, required this.ikanId});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  bool _isFavorite = false;
  bool _loadingFavorite = false;

  @override
  void initState() {
    super.initState();
    _cekFavorite();
  }

  Future<void> _cekFavorite() async {
    final user = auth.currentUser;
    if (user == null) return;
    final doc = await firestore
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(widget.ikanId)
        .get();
    if (mounted) setState(() => _isFavorite = doc.exists);
  }

  Future<void> _toggleFavorite(Map<String, dynamic> data) async {
    final user = auth.currentUser;
    if (user == null) {
      _tampilDialogLogin();
      return;
    }

    setState(() => _loadingFavorite = true);

    final ref = firestore
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(widget.ikanId);

    try {
      if (_isFavorite) {
        await ref.delete();
        setState(() => _isFavorite = false);
      } else {
        await ref.set({
          'ikanId': widget.ikanId,
          'nama': data['nama'] ?? '',
          'harga': data['harga'] ?? '',
          'kategori': data['kategori'] ?? '',
          'gambar': data['gambar'] ?? '',
          'lokasi': data['lokasi'] ?? '',
          'username': data['username'] ?? '',
          'created_at': FieldValue.serverTimestamp(),
        });
        setState(() => _isFavorite = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    } finally {
      if (mounted) setState(() => _loadingFavorite = false);
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
          "Kamu harus login atau membuat akun terlebih dahulu untuk menyimpan favorite.",
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

  void _bukaFullImage(String gambar) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _FullImageScreen(imageBase64: gambar)),
    );
  }

  // ── FETCH PERBANDINGAN HARGA ──
  Future<List<Map<String, dynamic>>> _fetchPerbandingan(
    String nama,
    String kategori,
    double lat,
    double lng,
  ) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('ikan')
          .where('nama', isEqualTo: nama)
          .where('kategori', isEqualTo: kategori)
          .get();

      final List<Map<String, dynamic>> hasil = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final docLat = (data['latitude'] as num?)?.toDouble();
        final docLng = (data['longitude'] as num?)?.toDouble();
        if (docLat == null || docLng == null) continue;

        final jarak = Geolocator.distanceBetween(lat, lng, docLat, docLng);
        if (jarak <= 1000) {
          hasil.add({...data, 'ikanId': doc.id, 'jarak': jarak});
        }
      }

      hasil.sort((a, b) {
        final hA = int.tryParse(a['harga'].toString()) ?? 0;
        final hB = int.tryParse(b['harga'].toString()) ?? 0;
        return hA.compareTo(hB);
      });

      return hasil;
    } catch (e) {
      debugPrint('Error fetching perbandingan: $e');
      return [];
    }
  }

  // ── DEFAULT AVATAR ──
  Widget _defaultAvatar() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.storefront, color: Colors.blue, size: 24),
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
          final userId = data['userId'] ?? '';
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

          // Parse lat/lng sekali untuk dipakai di beberapa tempat
          final double? parsedLat = latitude == null
              ? null
              : (latitude is num)
              ? latitude.toDouble()
              : double.tryParse(latitude.toString());
          final double? parsedLng = longitude == null
              ? null
              : (longitude is num)
              ? longitude.toDouble()
              : double.tryParse(longitude.toString());

          final hargaCurrent = int.tryParse(harga.toString()) ?? 0;

          return CommentTrigger(
            onSwipeUp: () => _bukaKomentar(widget.ikanId),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── APP BAR ──
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
                              fontSize: 16,
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

                    // ── GAMBAR ──
                    GestureDetector(
                      onTap: () {
                        if (gambar.toString().isNotEmpty) {
                          _bukaFullImage(gambar);
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: 260,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: gambar.toString().isNotEmpty
                            ? Stack(
                                children: [
                                  Positioned.fill(
                                    child: Image.memory(
                                      base64Decode(gambar),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 10,
                                    right: 10,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.4),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.fullscreen,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : const Icon(Icons.image, size: 80),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── FAVORIT (Kanan) ──
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: GestureDetector(
                          onTap: () => _toggleFavorite(data),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: _isFavorite
                                  ? Colors.red.shade50
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _loadingFavorite
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.red,
                                    ),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _isFavorite
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        size: 20,
                                        color: _isFavorite
                                            ? Colors.red
                                            : Colors.black87,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _isFavorite ? "Disimpan" : "Favorite",
                                        style: TextStyle(
                                          color: _isFavorite
                                              ? Colors.red
                                              : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
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
                          // ── NAMA & HARGA ──
                          Text(
                            nama,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            kategori,
                            style: const TextStyle(
                              color: Color(0xFF6C8EF5),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "${formatRupiah(harga)} / Kg",
                            style: const TextStyle(
                              color: Color(0xff6C8EF5),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 18),

                          // ── INFO PENJUAL ──
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TokoScreen(
                                    username: username,
                                    alamat: alamat,
                                    userId: userId,
                                  ),
                                ),
                              );
                            },
                            child: Container(
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
                                      fontSize: 14,
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
                                                fontSize: 14,
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
                                      const Icon(
                                        Icons.chevron_right,
                                        color: Colors.black38,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ── PERBANDINGAN HARGA INLINE ──
                          if (parsedLat != null && parsedLng != null)
                            FutureBuilder<List<Map<String, dynamic>>>(
                              future: _fetchPerbandingan(
                                nama,
                                kategori,
                                parsedLat,
                                parsedLng,
                              ),
                              builder: (context, snap) {
                                if (!snap.hasData || snap.data!.isEmpty) {
                                  return const SizedBox();
                                }

                                final lainnya = snap.data!
                                    .where(
                                      (item) => item['ikanId'] != widget.ikanId,
                                    )
                                    .toList();

                                if (lainnya.isEmpty) return const SizedBox();

                                final tampil = lainnya.take(3).toList();
                                final adaLebih = lainnya.length > 3;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Header
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xff6C8EF5,
                                                  ).withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: const Icon(
                                                  Icons.compare_arrows,
                                                  color: Color(0xff6C8EF5),
                                                  size: 18,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    "Perbandingan Harga",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  Text(
                                                    "Penjual $nama terdekat · 1km",
                                                    style: const TextStyle(
                                                      color: Colors.black45,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 16),
                                          const Divider(height: 1),
                                          const SizedBox(height: 14),

                                          // Card per penjual
                                          ...tampil.map((item) {
                                            final hargaItem =
                                                int.tryParse(
                                                  item['harga'].toString(),
                                                ) ??
                                                0;
                                            final selisih =
                                                hargaItem - hargaCurrent;
                                            final gambarItem =
                                                item['gambar']?.toString() ??
                                                '';

                                            String labelText;
                                            Color labelColor;
                                            IconData labelIcon;

                                            if (selisih < 0) {
                                              labelText =
                                                  'Lebih murah ${formatRupiah(selisih.abs())}';
                                              labelColor = const Color(
                                                0xFF27AE60,
                                              );
                                              labelIcon =
                                                  Icons.arrow_downward_rounded;
                                            } else if (selisih > 0) {
                                              labelText =
                                                  'Lebih mahal ${formatRupiah(selisih)}';
                                              labelColor = const Color(
                                                0xFFE74C3C,
                                              );
                                              labelIcon =
                                                  Icons.arrow_upward_rounded;
                                            } else {
                                              labelText = 'Harga sama';
                                              labelColor = Colors.grey;
                                              labelIcon = Icons.remove;
                                            }

                                            return GestureDetector(
                                              onTap: () => Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => DetailScreen(
                                                    ikanId: item['ikanId'],
                                                  ),
                                                ),
                                              ),
                                              child: Container(
                                                margin: const EdgeInsets.only(
                                                  bottom: 10,
                                                ),
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xffF5F5F5,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                ),
                                                child: Row(
                                                  children: [
                                                    // Avatar / Foto
                                                    ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      child:
                                                          gambarItem.isNotEmpty
                                                          ? Image.memory(
                                                              base64Decode(
                                                                gambarItem,
                                                              ),
                                                              width: 52,
                                                              height: 52,
                                                              fit: BoxFit.cover,
                                                              errorBuilder:
                                                                  (
                                                                    _,
                                                                    __,
                                                                    ___,
                                                                  ) =>
                                                                      _defaultAvatar(),
                                                            )
                                                          : _defaultAvatar(),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    // Info teks
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            item['username'] ??
                                                                '-',
                                                            style:
                                                                const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  fontSize: 13,
                                                                ),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                          const SizedBox(
                                                            height: 3,
                                                          ),
                                                          Text(
                                                            formatRupiah(
                                                              hargaItem,
                                                            ),
                                                            style:
                                                                const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 15,
                                                                  color: Color(
                                                                    0xff6C8EF5,
                                                                  ),
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                            height: 4,
                                                          ),
                                                          Row(
                                                            children: [
                                                              Icon(
                                                                labelIcon,
                                                                size: 12,
                                                                color:
                                                                    labelColor,
                                                              ),
                                                              const SizedBox(
                                                                width: 3,
                                                              ),
                                                              Text(
                                                                labelText,
                                                                style: TextStyle(
                                                                  fontSize: 11,
                                                                  color:
                                                                      labelColor,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const Icon(
                                                      Icons.chevron_right,
                                                      color: Colors.black26,
                                                      size: 18,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }),

                                          // Tombol lihat lainnya (hanya jika > 3)
                                          if (adaLebih) ...[
                                            const SizedBox(height: 4),
                                            GestureDetector(
                                              onTap: () => Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      PerbandinganScreen(
                                                        namaIkan: nama,
                                                        kategoriIkan: kategori,
                                                        userLatitude: parsedLat,
                                                        userLongitude:
                                                            parsedLng,
                                                        currentIkanId:
                                                            widget.ikanId,
                                                        currentHarga:
                                                            hargaCurrent,
                                                      ),
                                                ),
                                              ),
                                              child: Container(
                                                width: double.infinity,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 12,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xff6C8EF5,
                                                  ).withOpacity(0.07),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: const Color(
                                                      0xff6C8EF5,
                                                    ).withOpacity(0.25),
                                                  ),
                                                ),
                                                child: const Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      "Lihat perbandingan dari penjual lainnya",
                                                      style: TextStyle(
                                                        color: Color(
                                                          0xff6C8EF5,
                                                        ),
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                    SizedBox(width: 4),
                                                    Icon(
                                                      Icons.arrow_forward_ios,
                                                      color: Color(0xff6C8EF5),
                                                      size: 12,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                  ],
                                );
                              },
                            ),

                          // ── LOKASI ──
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
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                InkWell(
                                  onTap: (latitude != null && longitude != null)
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
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEEF1FE),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.map_outlined,
                                            color: Color(0xff6C8EF5),
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                lokasiText,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.black87,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              const Text(
                                                "Buka Google Maps",
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xff6C8EF5),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.open_in_new_rounded,
                                          color: Color(0xff6C8EF5),
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ── DESKRIPSI ──
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
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(deskripsi),
                                ],
                              ),
                            ),

                          if (deskripsi.toString().isNotEmpty)
                            const SizedBox(height: 20),

                          // ── DIPOSTING ──
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
                                    fontSize: 14,
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

// ── FULL IMAGE SCREEN ──
class _FullImageScreen extends StatelessWidget {
  final String imageBase64;
  const _FullImageScreen({required this.imageBase64});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Center(
          child: InteractiveViewer(
            child: Image.memory(base64Decode(imageBase64), fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}

// ── KOMENTAR SHEET ──
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
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
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
