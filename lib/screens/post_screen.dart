import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:wongiwak/screens/sign_in_screen.dart';

class PostScreen extends StatefulWidget {
  final bool isLogin;

  const PostScreen({super.key, required this.isLogin});

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  final TextEditingController namaController = TextEditingController();

  final TextEditingController hargaController = TextEditingController();

  final TextEditingController lokasiController = TextEditingController();

  String username = '';
  String alamat = '';

  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    if (widget.isLogin) {
      getUserData();
    }
  }

  Future<void> getUserData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final userData = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    setState(() {
      username = userData['username'];
      alamat = userData['alamat'];
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLogin) {
      return Scaffold(
        backgroundColor: const Color(0xffF5F5F5),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Belum bisa posting\nLogin terlebih dahulu",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xff6C8EF5),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: 120,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff6C8EF5),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),

                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignInScreen()),
                    );
                  },

                  child: const Text(
                    "Masuk",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xffF5F5F5),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },

                icon: const Icon(Icons.arrow_back_ios),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,

                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 3),

                      shape: BoxShape.circle,
                    ),

                    child: const CircleAvatar(
                      backgroundColor: Colors.grey,

                      child: Icon(Icons.person, color: Colors.white, size: 40),
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          username,

                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          alamat,

                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              Container(
                width: double.infinity,
                height: 130,

                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black38),

                  borderRadius: BorderRadius.circular(20),
                ),

                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [
                    Icon(Icons.add, size: 35, color: Colors.grey),

                    SizedBox(height: 10),

                    Text(
                      "Tambahkan Gambar",

                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 35),

              const Text(
                "Nama Ikan",

                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: namaController,

                decoration: InputDecoration(
                  hintText: "Contoh: Lele",
                  filled: true,
                  fillColor: Colors.white,

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                "Harga Ikan",

                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  SizedBox(
                    width: 150,

                    child: TextField(
                      controller: hargaController,
                      keyboardType: TextInputType.number,

                      decoration: InputDecoration(
                        hintText: "Rp 00",
                        filled: true,
                        fillColor: Colors.white,

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  const Text("/ Kg"),
                ],
              ),

              const SizedBox(height: 30),

              const Text(
                "Lokasi",

                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: lokasiController,

                decoration: InputDecoration(
                  hintText: "Masukkan lokasi",
                  filled: true,
                  fillColor: Colors.white,

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),

              const SizedBox(height: 50),

              Center(
                child: SizedBox(
                  width: 140,
                  height: 50,

                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff6C8EF5),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),

                    onPressed: () {},

                    child: const Text(
                      "Post",

                      style: TextStyle(color: Colors.white, fontSize: 18),
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
}
