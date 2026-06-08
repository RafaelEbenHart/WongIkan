import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late User? currentUser;
  late TextEditingController usernameController;
  late TextEditingController locationController;
  late TextEditingController occupationController;
  late TextEditingController alamatController;

  XFile? selectedImage;
  Uint8List? selectedImageBytes;
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    usernameController = TextEditingController();
    locationController = TextEditingController();
    occupationController = TextEditingController();
    alamatController = TextEditingController();
    _loadUserData();
  }

  @override
  void dispose() {
    usernameController.dispose();
    locationController.dispose();
    occupationController.dispose();
    alamatController.dispose();
    super.dispose();
  }

  void _loadUserData() async {
    if (currentUser != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          usernameController.text = data['username'] ?? '';
          locationController.text = data['location'] ?? '';
          occupationController.text =
              data['occupation'] ?? 'Penjual ikan segar';
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 40,
      maxWidth: 600,
      maxHeight: 600,
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      if (bytes.length > 800000) {
        _showSnackBar(
          'Ukuran gambar terlalu besar. Pilih gambar maksimal 1MB.',
        );
        return;
      }
      setState(() {
        selectedImage = image;
        selectedImageBytes = bytes;
      });
    }
  }

  void _saveProfile() async {
    if (currentUser == null) {
      _showSnackBar('User tidak login');
      return;
    }

    if (usernameController.text.isEmpty) {
      _showSnackBar('Username harus diisi');
      return;
    }

    setState(() => isUploading = true);

    try {
      Map<String, dynamic> updateData = {
        'username': usernameController.text.trim(),
        'location': locationController.text.trim(),
        'occupation': occupationController.text.trim(),
        'alamat': alamatController.text.trim(),
      };

      // Jika ada koordinat yang tersimpan, sertakan dalam update
      if (latitude != null && longitude != null) {
        updateData['latitude'] = latitude;
        updateData['longitude'] = longitude;
      }

      if (selectedImageBytes != null) {
        try {
          updateData['profileImageBytes'] = Blob(selectedImageBytes!);
        } catch (imageError) {
          _showSnackBar('Error gambar: $imageError');
        }
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .update(updateData);

      if (mounted) {
        _showSnackBar('✓ Profil berhasil diperbarui');
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            setState(() {
              selectedImage = null;
              selectedImageBytes = null;
            });
            Navigator.pop(context);
          }
        });
      }
    } catch (e) {
      _showSnackBar('Error menyimpan profil: $e');
    } finally {
      if (mounted) setState(() => isUploading = false);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        automaticallyImplyLeading: false,
        title: const Text(
          'Pengaturan Profil',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF5E7AC4),
                              width: 3,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: selectedImageBytes != null
                                ? MemoryImage(selectedImageBytes!)
                                : null,
                            child: selectedImageBytes == null
                                ? Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.grey.shade400,
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF5E7AC4),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Ubah Foto Profil',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Informasi Profil',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildTextField(
                label: 'Username',
                controller: usernameController,
                hintText: 'Masukkan username Anda',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Pekerjaan/Deskripsi',
                controller: occupationController,
                hintText: 'Misal: Penjual ikan segar',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Lokasi (Kota)',
                controller: locationController,
                hintText: 'Masukkan kota/lokasi Anda',
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Alamat Lengkap',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5E7AC4),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: alamatController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: 'Alamat akan terisi otomatis dari GPS',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Colors.grey.shade200,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Colors.grey.shade200,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFF5E7AC4),
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: isLoadingAlamat ? null : _ambilAlamatDariGPS,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF5E7AC4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: isLoadingAlamat
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.my_location,
                                  color: Colors.white,
                                  size: 22,
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 13,
                        color: Colors.black38,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Tekan icon GPS untuk mengisi alamat otomatis',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isUploading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5E7AC4),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: isUploading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Simpan Perubahan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      selectedImage = null;
                      selectedImageBytes = null;
                    });
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFF5E7AC4)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Batal',
                    style: TextStyle(
                      color: Color(0xFF5E7AC4),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF5E7AC4),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF5E7AC4), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            hintStyle: TextStyle(color: Colors.grey.shade400),
          ),
        ),
      ],
    );
  }
}
