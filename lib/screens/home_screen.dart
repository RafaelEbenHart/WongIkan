import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'post_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F5F5),

      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,

        title: const Text(
          "WongIkan",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15),

            child: CircleAvatar(
              backgroundColor: Colors.blue.shade100,

              child: const Icon(Icons.person, color: Colors.blue),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xff6C8EF5),

        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PostScreen(
                isLogin: FirebaseAuth.instance.currentUser != null,
              ),
            ),
          );
        },

        child: const Icon(Icons.add),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: const Color(0xff6C8EF5),
                borderRadius: BorderRadius.circular(25),
              ),

              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    "Pantau Harga\nIkan Segar",

                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 10),

                  Text(
                    "Cek harga ikan terbaru dari berbagai lokasi.",

                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              "Daftar Ikan",

              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('ikan')
                    .orderBy('created_at', descending: true)
                    .snapshots(),

                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("Belum ada data ikan"));
                  }

                  final data = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: data.length,

                    itemBuilder: (context, index) {
                      final ikan = data[index];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),

                        padding: const EdgeInsets.all(15),

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
                            Container(
                              width: 80,
                              height: 80,

                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,

                                borderRadius: BorderRadius.circular(15),
                              ),

                              child: const Icon(
                                Icons.set_meal,
                                size: 40,
                                color: Colors.blue,
                              ),
                            ),

                            const SizedBox(width: 15),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,

                                children: [
                                  Text(
                                    ikan['nama'],

                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height: 6),

                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        size: 16,
                                        color: Colors.grey,
                                      ),

                                      const SizedBox(width: 4),

                                      Text(
                                        ikan['lokasi'],

                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  Text(
                                    "Rp ${ikan['harga']} / Kg",

                                    style: const TextStyle(
                                      color: Color(0xff6C8EF5),

                                      fontWeight: FontWeight.bold,

                                      fontSize: 16,
                                    ),
                                  ),
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
          ],
        ),
      ),
    );
  }
}
