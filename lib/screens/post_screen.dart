import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wongiwak/screens/settings_screen.dart'; // Sesuaikan path ini jika berbeda

import 'sign_in_screen.dart';

class PostScreen extends StatefulWidget {
  final bool isLogin;

  const PostScreen({super.key, required this.isLogin});

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> with WidgetsBindingObserver {
  final TextEditingController namaController = TextEditingController();
  final TextEditingController hargaController = TextEditingController();
  final TextEditingController deskripsiController = TextEditingController();
  // lokasiController SUDAH DIHAPUS SEPENUHNYA

  Uint8List? imageBytes;
  String? base64Image;

  bool isLoading = true;
  bool isPosting = false;

  String username = '';
  String alamat = '';

  double? latitude;
  double? longitude;

  final ImagePicker picker = ImagePicker();

  String selectedKategori = 'Ikan Air Tawar';

  final List<String> kategoriList = [
    'Ikan Air Tawar',
    'Ikan Laut',
    'Ikan Hias',
    'Udang',
    'Kepiting',
    'Lobster',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.isLogin) {
      getUserData();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    namaController.dispose();
    hargaController.dispose();
    deskripsiController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.isLogin) {
      getUserData();
    }
  }

  Future<void> getUserData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (userData.exists) {
        final data = userData.data() as Map<String, dynamic>?;
        setState(() {
          username = data?['username'] ?? 'User';
          // Ambil dari 'location' (karena di ProfileScreen disimpannya dengan nama ini)
          // Jika kosong, ambil dari 'alamat', jika masih kosong, set string kosong ''
          alamat = data?['location'] ?? data?['alamat'] ?? '';
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      debugPrint('Error mengambil data user: $e');
    }
  }

  Future<void> getLocation() async {
    try {
      if (kIsWeb) {
        final position = await Geolocator.getCurrentPosition();
        latitude = position.latitude;
        longitude = position.longitude;
        return;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Layanan lokasi tidak diaktifkan')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Izin lokasi ditolak')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Izin lokasi ditolak permanen. Cek setting aplikasi',
              ),
            ),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      latitude = position.latitude;
      longitude = position.longitude;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error mengambil lokasi: $e')));
      }
    }
  }

  Future<void> pickImage() async {
    // Kualitas gambar dikompres agar tidak menyebabkan invalid-argument di Firestore
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 25,
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        imageBytes = bytes;
        base64Image = base64Encode(bytes);
      });
    }
  }

  void _tampilDialogAlamat() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Lokasi Belum Diisi",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Kamu belum mengatur lokasi/alamat. Silakan atur terlebih dahulu melalui pengaturan profil sebelum membuat postingan.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal", style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5E7AC4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ).then((_) => getUserData());
            },
            child: const Text(
              "Atur Lokasi",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> submitPost() async {
    // Validasi lokasi langsung pakai variabel alamat
    if (alamat.isEmpty) {
      _tampilDialogAlamat();
      return;
    }

    // Validasi controller text
    if (imageBytes == null ||
        namaController.text.isEmpty ||
        hargaController.text.isEmpty ||
        deskripsiController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lengkapi semua data')));
      return;
    }

    setState(() => isPosting = true);

    try {
      await getLocation();

      await FirebaseFirestore.instance.collection('ikan').add({
        'nama': namaController.text.trim(),
        'harga': hargaController.text.trim(),
        'deskripsi': deskripsiController.text.trim(),
        'lokasi': alamat, // Data lokasi diisi otomatis dari profil
        'alamat': alamat,
        'kategori': selectedKategori,
        'gambar': base64Image,
        'username': username,
        'userId': FirebaseAuth.instance.currentUser!.uid,
        'created_at': Timestamp.now(),
        'latitude': latitude,
        'longitude': longitude,
      });

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Posting berhasil')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLogin) {
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SignInScreen()),
              );
            },
            child: const Text("Login"),
          ),
        ),
      );
    }

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text("Post Ikan"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bagian Header & Gambar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Post Ikan Baru',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Unggah foto dan isi kategori, nama, harga, dan detail ikan.',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: pickImage,
                    child: Container(
                      width: double.infinity,
                      height: 220,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF3FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFD7E0FF)),
                      ),
                      child: imageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.memory(
                                imageBytes!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Center(
                              child: Icon(
                                Icons.add_a_photo,
                                size: 48,
                                color: Color(0xFF6C8EF5),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField(
                    value: selectedKategori,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF4F6FF),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: kategoriList.map((e) {
                      return DropdownMenuItem(value: e, child: Text(e));
                    }).toList(),
                    onChanged: (v) => setState(() => selectedKategori = v!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Bagian Detail Ikan
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Nama Ikan',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: namaController,
                    decoration: InputDecoration(
                      hintText: 'Contoh: Iwak',
                      filled: true,
                      fillColor: const Color(0xFFF4F6FF),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Detail Ikan',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: deskripsiController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Contoh: Ikan segar, ukuran besar, warna merah',
                      filled: true,
                      fillColor: const Color(0xFFF4F6FF),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // PERBAIKAN: Kotak Lokasi yang Bisa Dipencet (Clickable)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Lokasi',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      // Saat kotak dipencet, akan pindah ke SettingsScreen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      ).then(
                        (_) => getUserData(),
                      ); // Otomatis refresh data saat kembali
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: alamat.isEmpty
                            ? Colors.red.shade50
                            : const Color(0xFFF4F6FF),
                        borderRadius: BorderRadius.circular(16),
                        border: alamat.isEmpty
                            ? Border.all(color: Colors.red.shade200)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: alamat.isEmpty
                                ? Colors.red.shade400
                                : const Color(0xFF6C8EF5),
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              alamat.isEmpty
                                  ? 'Tap untuk atur lokasi di profil...'
                                  : alamat,
                              style: TextStyle(
                                color: alamat.isEmpty
                                    ? Colors.red.shade700
                                    : Colors.black87,
                                fontSize: 14,
                                fontWeight: alamat.isEmpty
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: Colors.black26,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Harga Ikan',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: hargaController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            hintText: 'Rp 00',
                            filled: true,
                            fillColor: const Color(0xFFF4F6FF),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 18,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        '/ Kg',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Tombol Post
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor: const Color(0xFF6C8EF5),
                      ),
                      onPressed: isPosting ? null : submitPost,
                      child: isPosting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Post',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
