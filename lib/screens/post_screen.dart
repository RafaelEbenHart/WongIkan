import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wongiwak/screens/settings_screen.dart';

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

  String? namaError;
  String? hargaError;
  String? deskripsiError;

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
        final data = userData.data();
        setState(() {
          username = data?['username'] ?? 'User';
          alamat = data?['location'] ?? data?['alamat'] ?? '';
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
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

  bool _validasi() {
    final nama = namaController.text.trim();
    final harga = hargaController.text.trim();
    final deskripsi = deskripsiController.text.trim();

    String? errNama;
    String? errHarga;
    String? errDeskripsi;

    if (nama.isEmpty) {
      errNama = 'Nama ikan tidak boleh kosong';
    } else if (nama.length > 200) {
      errNama = 'Nama ikan maksimal 200 karakter';
    }

    if (deskripsi.isEmpty) {
      errDeskripsi = 'Detail ikan tidak boleh kosong';
    } else if (deskripsi.length > 200) {
      errDeskripsi = 'Detail ikan maksimal 200 karakter';
    }

    if (harga.isEmpty) {
      errHarga = 'Harga tidak boleh kosong';
    } else {
      final hargaInt = int.tryParse(harga);
      if (hargaInt == null || hargaInt < 0) {
        errHarga = 'Harga tidak boleh minus';
      } else if (hargaInt > 10000000) {
        errHarga = 'Harga tidak boleh melebihi Rp 10.000.000';
      }
    }

    setState(() {
      namaError = errNama;
      hargaError = errHarga;
      deskripsiError = errDeskripsi;
    });

    return errNama == null && errHarga == null && errDeskripsi == null;
  }

  Future<void> submitPost() async {
    if (alamat.isEmpty) {
      _tampilDialogAlamat();
      return;
    }

    if (imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih foto ikan terlebih dahulu')),
      );
      return;
    }

    if (!_validasi()) return;

    setState(() => isPosting = true);

    try {
      await getLocation();

      await FirebaseFirestore.instance.collection('ikan').add({
        'nama': namaController.text.trim(),
        'harga': hargaController.text.trim(),
        'deskripsi': deskripsiController.text.trim(),
        'lokasi': alamat,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text(
                'Posting berhasil dibuat!',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) Navigator.pop(context);
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => isPosting = false);
    }
  }

  InputDecoration _inputDecoration({required String hint, String? errorText}) {
    return InputDecoration(
      hintText: hint,
      errorText: errorText,
      filled: true,
      fillColor: errorText != null
          ? Colors.red.shade50
          : const Color(0xFFF4F6FF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: errorText != null
            ? BorderSide(color: Colors.red.shade300)
            : BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: errorText != null
            ? BorderSide(color: Colors.red.shade400, width: 1.5)
            : const BorderSide(color: Color(0xFF6C8EF5), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.red.shade300),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
      ),
    );
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
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add_a_photo,
                                    size: 48,
                                    color: Color(0xFF6C8EF5),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Tap untuk pilih foto',
                                    style: TextStyle(
                                      color: Color(0xFF6C8EF5),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
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
                    'Nama Ikan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Maks. 200 karakter',
                    style: TextStyle(color: Colors.black38, fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: namaController,
                    maxLength: 200,
                    onChanged: (_) {
                      if (namaError != null) setState(() => namaError = null);
                    },
                    decoration: _inputDecoration(
                      hint: 'Contoh: Ikan Gurame',
                      errorText: namaError,
                    ).copyWith(counterText: ''),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Detail Ikan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Maks. 200 karakter',
                    style: TextStyle(color: Colors.black38, fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: deskripsiController,
                    maxLines: 3,
                    maxLength: 200,
                    onChanged: (_) {
                      if (deskripsiError != null) {
                        setState(() => deskripsiError = null);
                      }
                    },
                    decoration: _inputDecoration(
                      hint: 'Contoh: Ikan segar, ukuran besar, warna merah',
                      errorText: deskripsiError,
                    ).copyWith(counterText: ''),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Lokasi',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      ).then((_) => getUserData());
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
                  const Text(
                    'Harga Ikan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Maks. Rp 10.000.000 · tidak boleh minus',
                    style: TextStyle(color: Colors.black38, fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: hargaController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (_) {
                            if (hargaError != null) {
                              setState(() => hargaError = null);
                            }
                          },
                          decoration: _inputDecoration(
                            hint: 'Rp 00',
                            errorText: hargaError,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Padding(
                        padding: EdgeInsets.only(top: 18),
                        child: Text(
                          '/ Kg',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
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
