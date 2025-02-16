import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'AddProducts.dart';
import 'ProductDetailsPage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Grocery App',
      theme: ThemeData(
        primaryColor: Colors.green,
        scaffoldBackgroundColor: Colors.white,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 18, color: Colors.black),
          bodyMedium: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () async {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage(user: user)),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      body: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLoading = false;

  Future<void> signInWithGoogle() async {
    setState(() => isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
          "uid": user.uid,
          "name": user.displayName ?? "No Name",
          "email": user.email ?? "No Email",
          "photoURL": user.photoURL ?? "",
          "lastLogin": DateTime.now(),
        }, SetOptions(merge: true));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage(user: user)),
        );
      }
    } catch (e) {
      print("Google Sign-In Error: $e");
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const SizedBox(height: 50),
          Expanded(
            child: CarouselSlider(
              options: CarouselOptions(height: 250, autoPlay: true, enlargeCenterPage: true),
              items: [
                "lib/assets/e1.png",
                "lib/assets/e2.jpg",
                "lib/assets/e3.jpeg"
              ].map((imgPath) {
                return Image.asset(imgPath, fit: BoxFit.cover);
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Welcome to FreshMart 🍏",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Get fresh groceries delivered to your doorstep. Sign in to continue!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ),
          const SizedBox(height: 30),
          isLoading
              ? const CircularProgressIndicator()
              : ElevatedButton(
            onPressed: signInWithGoogle,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  "lib/assets/google.png",
                  height: 24,
                ),
                const SizedBox(width: 10),
                const Text("Sign in with Google", style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final User user;

  const HomePage({super.key, required this.user});

  Future<void> signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> products = [
      {"image": "lib/assets/apple.jpeg", "title": "Fresh Apples 🍏", "price": "Rs. 120/kg"},
      {"image": "lib/assets/banana.jpeg", "title": "Bananas 🍌", "price": "Rs. 60/kg"},
      {"image": "lib/assets/milk.jpeg", "title": "Organic Milk 🥛", "price": "Rs. 80/L"},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text("Welcome, ${user.displayName} 👋",style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            onPressed: () => signOut(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                "Today's Fresh Picks 🥑",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),

            // 🔥 FULL-WIDTH CAROUSEL 🔥
            CarouselSlider(
              options: CarouselOptions(
                height: 250,
                autoPlay: true,
                viewportFraction: 1.0, // Full Width
                enlargeCenterPage: true,
              ),
              items: products.map((product) {
                return fullWidthProductCard(product["image"]!, product["title"]!, product["price"]!);
              }).toList(),
            ),

            // 🔥 Categorized Products from Firestore
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection("products").snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text("No products available.", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ));
                }

                // 📌 Classify products dynamically
                List<DocumentSnapshot> perishableProducts = [];
                List<DocumentSnapshot> sizeVariantProducts = [];
                List<DocumentSnapshot> regularProducts = [];

                for (var doc in snapshot.data!.docs) {
                  var product = doc.data() as Map<String, dynamic>;
                  bool hasExpiryDate = product["hasExpiryDate"] ?? false;
                  bool hasSizeVariants = product["hasSizeVariants"] ?? false;

                  if (hasExpiryDate) {
                    perishableProducts.add(doc);
                  } else if (hasSizeVariants) {
                    sizeVariantProducts.add(doc);
                  } else {
                    regularProducts.add(doc);
                  }
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (perishableProducts.isNotEmpty) productCategorySection(context,"Perishable Products", perishableProducts),
                    if (sizeVariantProducts.isNotEmpty) productCategorySection(context,"Size-Variant Products", sizeVariantProducts),
                    if (regularProducts.isNotEmpty) productCategorySection(context,"Regular Products", regularProducts),
                  ],
                );
              },
            ),
          ],
        ),
      ),

      // 🚀 Floating Add Product Button
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add,color: Colors.white,),
        label: const Text("Add Product",style: TextStyle(color: Colors.white),),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductPage()),
          );
        },
      ),
    );
  }

  // 🌟 FULL-WIDTH PRODUCT CARD UI
  Widget fullWidthProductCard(String imgPath, String title, String price) {
    return Stack(
      children: [
        // Background Image
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5, spreadRadius: 2)],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.asset(imgPath, fit: BoxFit.cover, width: double.infinity, height: 250),
          ),
        ),

        // Overlay Text
        Positioned(
          bottom: 20,
          left: 20,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text(price, style: const TextStyle(color: Colors.greenAccent, fontSize: 16)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 🌟 PRODUCT CATEGORY SECTION
  Widget productCategorySection(BuildContext context,String title, List<DocumentSnapshot> products) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: products.map((doc) {
                var product = doc.data() as Map<String, dynamic>;
                product["id"] = doc.id;
                return productCard(context,product);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // 🖼 PRODUCT CARD UI
  Widget productCard(BuildContext context, Map<String, dynamic> product) {
    Uint8List? imageBytes;
    if (product["imageBase64"] != null) {
      imageBytes = base64Decode(product["imageBase64"]);
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsPage(product: product),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              child: imageBytes != null
                  ? Image.memory(imageBytes, height: 120, width: 160, fit: BoxFit.cover)
                  : Image.asset("lib/assets/broken.jpg", height: 120, width: 160, fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product["name"], style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (product["hasSizeVariants"] ?? false)
                    Text("Multiple Sizes Available", style: const TextStyle(color: Colors.grey)),
                  if (!(product["hasSizeVariants"] ?? false))
                    Text("Rs. ${product["price"]}", style: const TextStyle(color: Colors.green)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

