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
import 'package:intl/intl.dart';

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
        primaryColor: Color(0xFF4169E1),
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
      backgroundColor: Color(0xFF4169E1),
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
              backgroundColor: Color(0xFF4169E1),
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
      {"image": "lib/assets/apple.jpeg", "title": "Fresh Apples 🍏"},
      {"image": "lib/assets/banana.jpeg", "title": "Bananas 🍌"},
      {"image": "lib/assets/milk.jpeg", "title": "Organic Milk 🥛"},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text("Welcome, ${user.displayName} 👋",style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
        backgroundColor: Color(0xFF4169E1),
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
                return fullWidthProductCard(product["image"]!, product["title"]!);
              }).toList(),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('products')
                  .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox(); // No data yet

                List<DocumentSnapshot> lowStockProducts = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>?; // Safe access
                  if (data == null || !data.containsKey("quantity")) return false;

                  int quantity = int.tryParse(data["quantity"].toString()) ?? 0;

                  // Check stock based on type
                  if (data["hasSizeVariants"] == true) {
                    // If product has size variants, check all sizes
                    List<dynamic> sizeVariants = data["sizeVariants"] ?? [];

                    // Check if any size variant has a quantity <= 0
                    return sizeVariants.any((sizeData) {
                      if (sizeData is Map<String, dynamic>) {
                        int sizeQty = int.tryParse(sizeData["quantity"].toString()) ?? 0;
                        return sizeQty <= 0;
                      }
                      return false;
                    });
                  }

                  return quantity <= 0; // For regular products
                }).toList();

                if (lowStockProducts.isEmpty) return const SizedBox(); // No low stock items

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    color: Colors.redAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      leading: const Icon(Icons.warning, color: Colors.white),
                      title: const Text(
                        "Low Stock Alert!",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var doc in lowStockProducts)
                            Text(
                              doc["hasSizeVariants"] == true
                                  ? "${doc["name"]} (Size: ${_getLowStockSizes(doc["sizeVariants"])})"
                                  : "${doc["name"]} (${doc["quantity"]})",
                              style: const TextStyle(color: Colors.white),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            // 🔥 Categorized Products from Firestore
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                  .snapshots(),
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
      StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("sales")
            .where("userId", isEqualTo: FirebaseAuth.instance.currentUser!.uid) // Filter by current user
            .orderBy("timestamp", descending: true) // Order by latest sales first
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          var sales = snapshot.data!.docs;

          // Group sales by product type and expiry
          Map<String, List<Map<String, dynamic>>> groupedSales = {
            "Perishable": [],
            "Regular": [],
            "Size Variants": [],
            "Expiry Products": [],  // New group for products with expiry
          };

          for (var doc in sales) {
            var sale = doc.data() as Map<String, dynamic>;

            // Determine type for size variants
            String type = sale["hasSizeVariants"] == true ? "Size Variants" : sale["type"] ?? "Regular";

            // Check if product has expiry date and group accordingly
            if (sale["hasExpiryDate"] == true) {
              groupedSales["Expiry Products"]?.add(sale);
            } else {
              groupedSales[type]?.add(sale);
            }
          }

          return ListView(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text("Recent Sales 🛒", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),

              // Display sales grouped by type
              for (var entry in groupedSales.entries)
                if (entry.value.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      "${entry.key} Products",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: entry.value.length,
                    itemBuilder: (context, index) {
                      var sale = entry.value[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          leading: CircleAvatar(child: Text("${sale["quantitySold"]}x")),
                          title: Text(sale["name"], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (sale["hasSizeVariants"] == true)
                                Text("Size: ${sale["size"]}", style: const TextStyle(color: Colors.grey)),
                              Text("Total: Rs. ${sale["totalAmount"]}", style: const TextStyle(fontWeight: FontWeight.w500)),
                            ],
                          ),
                          trailing: Text(
                            sale["timestamp"] != null
                                ? DateFormat.yMMMd().format(sale["timestamp"].toDate())
                                : "",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      );
                    },
                  ),
                ],
            ],
          );
        },
      ),
      ],
        ),
      ),

      // 🚀 Floating Add Product Button
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Color(0xFF4169E1),
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
  String _getLowStockSizes(List<dynamic> sizeVariants) {
    // Filter for low stock sizes and map them into a list of strings
    List<String> lowStockSizes = sizeVariants
        .where((sizeData) {
      // Safely parse quantity and check if it's <= 0
      if (sizeData is Map<String, dynamic>) {
        final qty = int.tryParse(sizeData["quantity"].toString());
        return qty != null && qty <= 0;
      }
      return false;
    })
        .map((sizeData) => "Size: ${sizeData["size"]}")
        .toList();

    // Return the joined list of sizes or empty string if no low stock sizes found
    return lowStockSizes.isEmpty ? "No sizes left" : lowStockSizes.join(", ");
  }



  // 🌟 FULL-WIDTH PRODUCT CARD UI
  Widget fullWidthProductCard(String imgPath, String title) {
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
                    Text("Rs. ${product["price"]}", style: const TextStyle(color: Color(0xFF4169E1))),

                  // 🔥 "Sell" Button
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: () => _sellProduct(context, product),
                      icon: const Icon(Icons.shopping_cart, color: Color(0xFF4169E1)), // Change the icon as needed
                      tooltip: "Sell Product", // Shows tooltip on long press
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
  void _sellProduct(BuildContext context, Map<String, dynamic> product) {
    TextEditingController quantityController = TextEditingController();
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

    List<dynamic> sizeVariants = product["sizeVariants"] ?? []; // Get available size variants
    String? selectedSize; // Track selected size
    String selectedPrice = ""; // Default price, will be set after size selection

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              const Icon(Icons.shopping_cart, color: Colors.blueAccent),
              const SizedBox(width: 10),
              Text(
                "Sell ${product['name']}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Show Size Variant Dropdown only if product has size variants
                if (product["hasSizeVariants"] == true)
                  DropdownButtonFormField<String>(
                    value: selectedSize,
                    hint: const Text("Select Size"),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.straighten),
                    ),
                    items: sizeVariants.map<DropdownMenuItem<String>>((variant) {
                      return DropdownMenuItem<String>(
                        value: variant["size"].toString(),
                        child: Text("Size: ${variant["size"]} - Price: ${variant["price"]}"),
                      );
                    }).toList(),
                    onChanged: (value) {
                      selectedSize = value;
                      // Update price based on selected size
                      final selectedVariant = sizeVariants.firstWhere(
                            (variant) => variant["size"].toString() == value,
                        orElse: () => {}, // Fallback if no size is selected
                      );
                      selectedPrice = selectedVariant["price"]?.toString() ?? ""; // Use the price from the selected size
                    },
                  ),
                const SizedBox(height: 10),

                // If product has no size variants, set the price to the default price
                if (product["hasSizeVariants"] == false)
                  Text(
                    "Price: ${product["price"]}",
                    style: const TextStyle(fontSize: 16),
                  ),

                const SizedBox(height: 10),

                // Quantity Input Field
                TextFormField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: "Enter quantity",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.production_quantity_limits),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Please enter a quantity";
                    if (int.tryParse(value) == null || int.parse(value) <= 0) return "Enter a valid quantity";
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton.icon(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  int quantity = int.parse(quantityController.text);
                  // If product has size variants, use the selected size and price
                  if (product["hasSizeVariants"] == true && selectedPrice.isNotEmpty) {
                    await _processSale(product, quantity, selectedSize, selectedPrice);
                    Navigator.pop(context);
                  }
                  // If product has no size variants, use the default price
                  else if (product["hasSizeVariants"] == false) {
                    await _processSale(product, quantity, null, product["price"].toString());
                    Navigator.pop(context);
                  } else {
                    // Handle error case where no size/price is selected
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please select a size")),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.check),
              label: const Text("Confirm Sale"),
            ),
          ],
        );
      },
    );
  }


  Future<void> _processSale(
      Map<String, dynamic> product, int quantitySold, String? selectedSize, String selectedPrice) async {
    String productId = product["id"];
    List<dynamic> sizeVariants = product["sizeVariants"] ?? [];
    int price = int.tryParse(selectedPrice) ?? 0; // Convert price to int

    if (product["hasSizeVariants"] == true) {
      // For products with size variants
      // Find the selected size variant
      var selectedVariant = sizeVariants.firstWhere((variant) => variant["size"] == selectedSize, orElse: () => null);
      if (selectedVariant == null) {
        print("Invalid size selection!");
        return;
      }

      int currentStock = int.tryParse(selectedVariant["quantity"] ?? "0") ?? 0;

      if (quantitySold > currentStock) {
        print("Not enough stock!");
        return;
      }

      // Update Firestore: Deduct stock for selected size
      selectedVariant["quantity"] = (currentStock - quantitySold).toString();

      await FirebaseFirestore.instance.collection("products").doc(productId).update({
        "sizeVariants": sizeVariants, // Update the sizeVariants with new quantity
      });
    } else {
      // For products without size variants (regular product)
      int currentStock = int.tryParse(product["quantity"] ?? "0") ?? 0;

      if (quantitySold > currentStock) {
        print("Not enough stock!");
        return;
      }

      // Update Firestore: Deduct stock for the regular product
      await FirebaseFirestore.instance.collection("products").doc(productId).update({
        "quantity": (currentStock - quantitySold).toString(), // Update the regular product quantity
      });
    }

    // Add Sale Record
    await FirebaseFirestore.instance.collection("sales").add({
      "productId": productId,
      "userId": FirebaseAuth.instance.currentUser!.uid,
      "name": product["name"],
      "quantitySold": quantitySold,
      "price": price,
      "totalAmount": quantitySold * price,
      "size": selectedSize ?? "N/A",
      "hasExpiryDate": product["hasExpiryDate"] ?? false,
      "expiryDate": product["expiryDate"] ?? "",
      "hasSizeVariants": product["hasSizeVariants"] ?? false,
      "type": product["type"] ?? "Unknown",
      "timestamp": FieldValue.serverTimestamp(),
    });

    print("Sale processed successfully!");
  }

}

