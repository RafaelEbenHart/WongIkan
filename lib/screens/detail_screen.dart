import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class DetailScreen extends StatefulWidget {
  final String ikanId;

  const DetailScreen({super.key, required this.ikanId});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final TextEditingController _komentarController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  bool _isSendingKomentar = false;

  String _formatRupiah(dynamic harga) {
    final number = int.tryParse(harga.toString()) ?? 0;
    final str = number.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
      count++;
    }
    return 'Rp ${buffer.toString().split('').reversed.join('')},00';
  }

  Future<void> _kirimKomentar() async {
    final teks = _komentarController.text.trim();
    if (teks.isEmpty) return;

    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login terlebih dahulu untuk berkomentar'),
          backgroundColor: Color(0xff6C8EF5),
        ),
      );
      return;
    }

    setState(() => _isSendingKomentar = true);

    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .get();
      final username = userDoc.exists
          ? (userDoc['username'] ?? 'Pengguna')
          : 'Pengguna';

      await _firestore
          .collection('ikan')
          .doc(widget.ikanId)
          .collection('komentar')
          .add({
            'uid': _currentUser!.uid,
            'username': username,
            'teks': teks,
            'created_at': FieldValue.serverTimestamp(),
          });

      _komentarController.clear();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengirim komentar: $e')));
    } finally {
      setState(() => _isSendingKomentar = false);
    }
  }

  void _share(Map<String, dynamic> data) {
    final nama = data['nama'] ?? '';
    final harga = _formatRupiah(data['harga'] ?? 0);
    final lokasi = data['lokasi'] ?? '';
    Share.share(
      '🐟 *$nama* — $harga/Kg\n📍 $lokasi\n\nCek harga ikan segar di WongIkan!',
      subject: 'Info Harga $nama - WongIkan',
    );
  }

  @override
  void dispose() {
    _komentarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F5F5),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('ikan').doc(widget.ikanId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xff6C8EF5)),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Data tidak ditemukan'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final nama = data['nama'] ?? '';
          final harga = data['harga'] ?? 0;
          final lokasi = data['lokasi'] ?? '';
          final penjual = data['penjual'] ?? data['username'] ?? '-';
          final alamatPenjual = data['alamat'] ?? lokasi;
          final imageUrl = data['image_url'] as String?;
          final diskon = data['diskon'] as int?;

          final hargaAsli = int.tryParse(harga.toString()) ?? 0;
          final hargaDiskon = diskon != null
              ? (hargaAsli * (100 - diskon) ~/ 100)
              : hargaAsli;

          return SafeArea(
            child: Column(
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
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.07),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.arrow_back_ios_new, size: 18),
                        ),
                      ),

                      const Text(
                        'Detail',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _share(data),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.07),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.reply, size: 22),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 220,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: imageUrl != null && imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) =>
                                      _fishPlaceholder(),
                                )
                              : _fishPlaceholder(),
                        ),

                        const SizedBox(height: 20),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              nama,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Padding(
                              padding: EdgeInsets.only(bottom: 3),
                              child: Text(
                                '/Kg',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black45,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        if (diskon != null) ...[
                          Text(
                            _formatRupiah(hargaAsli),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black38,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatRupiah(hargaDiskon),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff6C8EF5),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.red.shade200,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.trending_down,
                                  size: 14,
                                  color: Colors.red.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Diskon $diskon% lebih murah',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else
                          Text(
                            _formatRupiah(hargaAsli),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff6C8EF5),
                            ),
                          ),

                        const SizedBox(height: 24),

                        _sectionTitle('Info Penjual'),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.blue.shade100,
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.blue,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      penjual,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.location_on,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            alamatPenjual,
                                            style: const TextStyle(
                                              color: Colors.black54,
                                              fontSize: 13,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        _sectionTitle('Grafik Harga'),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: StreamBuilder<QuerySnapshot>(
                            stream: _firestore
                                .collection('ikan')
                                .where('nama', isEqualTo: nama)
                                .limit(5)
                                .snapshots(),
                            builder: (context, snap) {
                              if (snap.connectionState ==
                                  ConnectionState.waiting) {
                                return const SizedBox(
                                  height: 150,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xff6C8EF5),
                                    ),
                                  ),
                                );
                              }

                              final docs = snap.data?.docs ?? [];
                              if (docs.isEmpty) {
                                return const SizedBox(
                                  height: 80,
                                  child: Center(
                                    child: Text('Belum ada data harga'),
                                  ),
                                );
                              }

                              int maxHarga = 0;
                              for (final d in docs) {
                                final h =
                                    int.tryParse(d['harga'].toString()) ?? 0;
                                if (h > maxHarga) maxHarga = h;
                              }

                              return Column(
                                children: [
                                  SizedBox(
                                    height: 160,
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: docs.map((doc) {
                                        final docHarga =
                                            int.tryParse(
                                              doc['harga'].toString(),
                                            ) ??
                                            0;
                                        final isCurrentSeller =
                                            doc.id == widget.ikanId;
                                        final ratio = maxHarga > 0
                                            ? docHarga / maxHarga
                                            : 0.5;
                                        final barHeight = 100.0 * ratio + 20;

                                        return _BarItem(
                                          harga: docHarga,
                                          barHeight: barHeight,
                                          isCurrent: isCurrentSeller,
                                          formatRupiah: _formatRupiah,
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      'Penjual saat ini',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        color: const Color(0xff6C8EF5),
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'Penjual ini',
                                        style: TextStyle(fontSize: 11),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        width: 12,
                                        height: 12,
                                        color: Colors.green.shade400,
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'Penjual lain',
                                        style: TextStyle(fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 24),

                        _sectionTitle('Komentar'),
                        const SizedBox(height: 12),

                        StreamBuilder<QuerySnapshot>(
                          stream: _firestore
                              .collection('ikan')
                              .doc(widget.ikanId)
                              .collection('komentar')
                              .orderBy('created_at', descending: false)
                              .snapshots(),
                          builder: (context, snapKom) {
                            if (snapKom.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xff6C8EF5),
                                ),
                              );
                            }

                            final komentar = snapKom.data?.docs ?? [];

                            if (komentar.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Belum ada komentar. Jadilah yang pertama!',
                                    style: TextStyle(color: Colors.black45),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            }

                            return Column(
                              children: komentar.map((kom) {
                                final komData =
                                    kom.data() as Map<String, dynamic>;
                                return _KomentarTile(
                                  username: komData['username'] ?? 'Pengguna',
                                  teks: komData['teks'] ?? '',
                                );
                              }).toList(),
                            );
                          },
                        ),

                        const SizedBox(height: 24),
                        _sectionTitle('Tambah Komentar'),
                        const SizedBox(height: 12),

                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _komentarController,
                                  maxLines: null,
                                  decoration: InputDecoration(
                                    hintText: 'Tulis ulasan...',
                                    hintStyle: const TextStyle(
                                      color: Colors.black38,
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xffF5F5F5),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: _isSendingKomentar
                                    ? null
                                    : _kirimKomentar,
                                child: Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: const Color(0xff6C8EF5),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: _isSendingKomentar
                                      ? const Padding(
                                          padding: EdgeInsets.all(12),
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.send,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _fishPlaceholder() {
    return Center(
      child: Icon(Icons.set_meal, size: 80, color: Colors.blue.shade200),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }
}

class _BarItem extends StatelessWidget {
  final int harga;
  final double barHeight;
  final bool isCurrent;
  final String Function(dynamic) formatRupiah;

  const _BarItem({
    required this.harga,
    required this.barHeight,
    required this.isCurrent,
    required this.formatRupiah,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCurrent ? const Color(0xff6C8EF5) : Colors.green.shade400;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          formatRupiah(harga).replaceAll('Rp ', '').replaceAll(',00', ''),
          style: const TextStyle(fontSize: 10, color: Colors.black54),
        ),
        const SizedBox(height: 4),
        Container(
          width: 36,
          height: barHeight,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
        ),
      ],
    );
  }
}

class _KomentarTile extends StatelessWidget {
  final String username;
  final String teks;

  const _KomentarTile({required this.username, required this.teks});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.blue.shade100,
            child: Text(
              username.isNotEmpty ? username[0].toUpperCase() : '?',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  teks,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
