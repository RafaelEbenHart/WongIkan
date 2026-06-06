import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
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
  XFile? selectedImage;
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    usernameController = TextEditingController();
    locationController = TextEditingController();
    occupationController = TextEditingController();
    _loadUserData();
  }

  @override
  void dispose() {
    usernameController.dispose();
    locationController.dispose();
    occupationController.dispose();
    super.dispose();
  }

  void _loadUserData() async {
    if (currentUser != null) {
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
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        selectedImage = image;
      });
    }
  }

  Future<String?> _uploadProfileImage() async {
    if (selectedImage == null || currentUser == null) {
      print('Upload failed: selectedImage or currentUser is null');
      return null;
    }

    try {
      print('Starting image upload...');
      final bytes = await selectedImage!.readAsBytes();
      print('Image bytes read: ${bytes.length} bytes');

      final fileName =
          'profile_pictures/${currentUser!.uid}_${DateTime.now().millisecondsSinceEpoch}';
      print('Uploading to: $fileName');

      final ref = FirebaseStorage.instance.ref().child(fileName);

      // Upload dengan metadata
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      final uploadTask = await ref.putData(bytes, metadata);

      print('Upload complete: ${uploadTask.ref.fullPath}');
      final downloadUrl = await ref.getDownloadURL();
      print('Download URL: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      throw Exception('Gagal upload gambar: $e');
    }
  }

  void _saveProfile() async {
    if (currentUser == null) {
      _showSnackBar('User tidak login');
      return;
    }

    if (usernameController.text.isEmpty || locationController.text.isEmpty) {
      _showSnackBar('Semua field harus diisi');
      return;
    }

    setState(() => isUploading = true);

    try {
      Map<String, dynamic> updateData = {
        'username': usernameController.text,
        'location': locationController.text,
        'occupation': occupationController.text,
      };

      if (selectedImage != null) {
        try {
          final imageUrl = await _uploadProfileImage();
          if (imageUrl != null) {
            updateData['profileImage'] = imageUrl;
            print('Image URL added to update data');
          } else {
            print('Image URL is null');
            _showSnackBar(
              'Peringatan: Gambar tidak terupload, tapi profil disimpan',
            );
          }
        } catch (imageError) {
          print('Image upload error: $imageError');
          _showSnackBar('Error gambar: $imageError');
          // Continue saving profile data even if image upload fails
        }
      }

      print('Updating user data to Firestore...');
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .update(updateData);

      print('Update successful');
      if (mounted) {
        _showSnackBar('✓ Profil berhasil diperbarui');
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    } catch (e) {
      print('Profile save error: $e');
      _showSnackBar('Error: $e');
    } finally {
      if (mounted) setState(() => isUploading = false);
    }
  }

  void _showSnackBar(String message) {
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
              // Profile Picture Section
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
                          child: selectedImage != null
                              ? FutureBuilder<Uint8List>(
                                  future: selectedImage!.readAsBytes(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      return CircleAvatar(
                                        radius: 60,
                                        backgroundColor: Colors.grey.shade200,
                                        backgroundImage: MemoryImage(
                                          snapshot.data!,
                                        ),
                                      );
                                    }
                                    return CircleAvatar(
                                      radius: 60,
                                      backgroundColor: Colors.grey.shade200,
                                      child: Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Colors.grey.shade400,
                                      ),
                                    );
                                  },
                                )
                              : CircleAvatar(
                                  radius: 60,
                                  backgroundColor: Colors.grey.shade200,
                                  child: Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.grey.shade400,
                                  ),
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
              // Form Fields
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
                label: 'Lokasi',
                controller: locationController,
                hintText: 'Masukkan kota/lokasi Anda',
              ),
              const SizedBox(height: 32),
              // Buttons
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
                  onPressed: () => Navigator.pop(context),
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
