import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Import Image Picker
import 'package:saver_gallery/saver_gallery.dart';
import 'package:permission_handler/permission_handler.dart';
class ProductDetailsPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailsPage({Key? key, required this.product}) : super(key: key);

  @override
  _ProductDetailsPageState createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  bool isEditing = false;
  late TextEditingController nameController;
  late TextEditingController typeController;
  late TextEditingController expiryDateController;
  late TextEditingController priceController;
  late TextEditingController quantityController;
  Uint8List? imageBytes;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.product["name"]);
    typeController = TextEditingController(text: widget.product["type"]);
    expiryDateController = TextEditingController(text: widget.product["expiryDate"] ?? "");
    priceController = TextEditingController(text: widget.product["price"] ?? "");
    quantityController = TextEditingController(text: widget.product["quantity"]?.toString() ?? "");

    if (widget.product["imageBase64"] != null) {
      imageBytes = base64Decode(widget.product["imageBase64"]);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    typeController.dispose();
    expiryDateController.dispose();
    priceController.dispose();
    quantityController.dispose();
    super.dispose();
  }

  // Function to select a new image
  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      Uint8List bytes = await pickedFile.readAsBytes();
      String base64Image = base64Encode(bytes);

      setState(() {
        imageBytes = bytes;
        widget.product["imageBase64"] = base64Image; // Update product data
      });
    }
  }

  void toggleEditMode() {
    setState(() {
      isEditing = !isEditing;
    });
  }

  Future<void> requestPermissions() async {
    if (await Permission.storage.request().isGranted ||
        await Permission.photos.request().isGranted) {
      print("✅ Storage permission granted");
    } else {
      print("❌ Storage permission denied");
    }
  }
  Future<void> saveChanges() async {
    setState(() {
      widget.product["name"] = nameController.text.trim();
      widget.product["type"] = typeController.text.trim();
      widget.product["expiryDate"] = expiryDateController.text.trim();
      if (priceController.text.trim().isNotEmpty) {
        widget.product["price"] = priceController.text.trim();
      }
      if (quantityController.text.trim().isNotEmpty) {
        widget.product["quantity"] = quantityController.text.trim();
      }
      // Ensure size variants data is properly updated
      if (widget.product["hasSizeVariants"] == true && widget.product["sizeVariants"] != null) {
        for (int i = 0; i < widget.product["sizeVariants"].length; i++) {
          widget.product["sizeVariants"][i]["size"] = widget.product["sizeVariants"][i]["size"].toString().trim();
          widget.product["sizeVariants"][i]["price"] = widget.product["sizeVariants"][i]["price"].toString().trim();
          widget.product["sizeVariants"][i]["quantity"] = widget.product["sizeVariants"][i]["quantity"].toString().trim();
        }
      }

      isEditing = false;
    });

    try {
      // 🔥 Update Firebase
      await FirebaseFirestore.instance
          .collection("products")
          .doc(widget.product["id"])
          .update(widget.product);

      _showSnackbar(context, "Product details updated successfully!", true);
    } catch (e) {
      _showSnackbar(context, "Failed to update product. Try again!", false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.product["name"],
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Tooltip(
            message: isEditing ? "Save Changes" : "Edit Product",
            child: IconButton(
              icon: Icon(isEditing ? Icons.save : Icons.edit, color: Colors.white),
              onPressed: isEditing ? saveChanges : toggleEditMode,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼️ Product Image
            Center(
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: imageBytes != null
                          ? Image.memory(imageBytes!, width: double.infinity, height: 250, fit: BoxFit.cover)
                          : Image.asset("lib/assets/broken.jpg", width: double.infinity, height: 250, fit: BoxFit.cover),
                    ),
                  ),
                  if (isEditing)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.white),
                        onPressed: pickImage,
                        tooltip: "Change Image",
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                          shape: const CircleBorder(),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // Product Details Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildEditableField("Product Name", nameController),
                    const SizedBox(height: 10),
                    buildEditableField("Product Type", typeController),

                    // Expiry Date (if applicable)
                    if (widget.product["hasExpiryDate"] == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: buildEditableField("Expiry Date", expiryDateController, icon: Icons.calendar_today),
                      ),

                    const SizedBox(height: 20),

                    // Size Variants Section
                    if (widget.product["hasSizeVariants"] == true && widget.product["sizeVariants"] != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Available Sizes:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 5),
                          ...List.generate(widget.product["sizeVariants"].length, (index) {
                            var variant = widget.product["sizeVariants"][index];

                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.grey[200],
                              ),
                              child: Row(
                                children: [
                                  // Editable Size Field
                                  Expanded(
                                    child: TextField(
                                      controller: TextEditingController(text: variant["size"]),
                                      enabled: isEditing,
                                      onChanged: (val) => setState(() {
                                        widget.product["sizeVariants"][index]["size"] = val;
                                      }),
                                      decoration: const InputDecoration(labelText: "Size"),
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Editable Price Field
                                  Expanded(
                                    child: TextField(
                                      controller: TextEditingController(text: variant["price"]),
                                      enabled: isEditing,
                                      keyboardType: TextInputType.number,
                                      onChanged: (val) => setState(() {
                                        widget.product["sizeVariants"][index]["price"] = val;
                                      }),
                                      decoration: const InputDecoration(labelText: "Price (Rs.)"),
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Editable Quantity Field (if applicable)
                                  if (variant.containsKey("quantity"))
                                    Expanded(
                                      child: TextField(
                                        controller: TextEditingController(text: variant["quantity"].toString()),
                                        enabled: isEditing,
                                        keyboardType: TextInputType.number,
                                        onChanged: (val) => setState(() {
                                          widget.product["sizeVariants"][index]["quantity"] = val;
                                        }),
                                        decoration: const InputDecoration(labelText: "Quantity"),
                                      ),
                                    ),

                                  // Delete Button (Only in Edit Mode)
                                  if (isEditing)
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        setState(() {
                                          widget.product["sizeVariants"].removeAt(index);
                                        });
                                      },
                                    ),
                                ],
                              ),
                            );
                          }),

                          // Add New Size Button (Only in Edit Mode)
                          if (isEditing)
                            Center(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.add),
                                label: const Text("Add New Size"),
                                onPressed: () {
                                  setState(() {
                                    if (widget.product["sizeVariants"] == null) {
                                      widget.product["sizeVariants"] = [];
                                    }
                                    widget.product["sizeVariants"].add({"size": "", "price": "", "quantity": ""});
                                  });
                                },
                              ),
                            ),
                        ],
                      )
                    else
                      buildEditableField("Price", priceController, isNumber: true, icon: Icons.currency_rupee),

                    const SizedBox(height: 20),

                    // Quantity (If Available)
                    if (widget.product.containsKey("quantity") && widget.product["quantity"] != null)
                      buildEditableField("Quantity", quantityController, isNumber: true, icon: Icons.shopping_cart),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            // Cancel Button (Only in Edit Mode)
            if (isEditing)
              Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                    elevation: 5,
                  ),
                  icon: const Icon(Icons.cancel, color: Colors.white),
                  label: const Text("Cancel Editing", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    setState(() {
                      isEditing = false;
                      imageBytes = base64Decode(widget.product["imageBase64"]);
                    });
                  },
                ),
              ),

            // **Delete Product Button (Only when NOT editing)**
            if (!isEditing)
              Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                    elevation: 5,
                  ),
                  icon: const Icon(Icons.delete, color: Colors.white),
                  label: const Text("Delete Product", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  onPressed: confirmDelete,
                ),
              ),
            // QR Code Display (Centered Below Delete Button)
            if (!isEditing && widget.product["qrcode"] != null)
              Column(
                children: [
                  const SizedBox(height: 20),

                  // 🌟 Centered Text
                  const Center(
                    child: Text(
                      "Product Code Build 🛠️\nLong press to download and use on your products",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 🌟 QR Code with Long Press to Download
    Center(
    child: GestureDetector(
    onLongPress: () async {
    try {
    await requestPermissions();

    final Uint8List bytes = base64Decode(widget.product["qrcode"]);

    final result = await SaverGallery.saveImage(
    bytes,
    quality: 100, // Maximum quality for QR code clarity
    androidRelativePath: "Pictures/QR Codes",
    skipIfExists: false, fileName: 'qrcode_${DateTime.now().millisecondsSinceEpoch}.png',
    );

    if (result.isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("✅ QR Code Saved to Gallery!")),
    );
    } else {
    throw Exception("Failed to save image");
    }
    } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("❌ Failed to Save QR Code: $error")),
    );
    print(error);
    }
    },
    child: Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(10),
    color: Colors.white,
    boxShadow: [
    BoxShadow(
    color: Colors.black26,
    blurRadius: 8,
    spreadRadius: 2,
    offset: const Offset(0, 4),
    ),
    ],
    ),
    child: Image.memory(
    base64Decode(widget.product["qrcode"]),
    width: 200,
    height: 200,
    fit: BoxFit.cover,
    ),
    ),
    ),
    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

// Delete Confirmation Dialog
  void confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // Rounded Corners
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red, size: 28),
            const SizedBox(width: 10),
            const Text(
              "Delete Product",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          "Are you sure you want to delete this product? This action cannot be undone.",
          style: TextStyle(fontSize: 16),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly, // Center-align buttons
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.cancel, color: Colors.white),
            label: const Text("Cancel",style: TextStyle(color: Colors.white),),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete, color: Colors.white),
            label: const Text("Delete",style: TextStyle(color: Colors.white),),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () {
              deleteProduct();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }


// Delete Product Function
  void deleteProduct() async {
    try {
      await FirebaseFirestore.instance
          .collection('products') // Replace with your actual collection name
          .doc(widget.product["id"]) // Assuming "id" is the document ID
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Product deleted successfully"), backgroundColor: Colors.green),
      );

      Navigator.pop(context); // Navigate back after deletion
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting product: $error"), backgroundColor: Colors.red),
      );
    }
  }

  Widget buildEditableField(String label, TextEditingController controller, {bool isNumber = false, IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          enabled: isEditing,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            prefixIcon: icon != null ? Icon(icon) : null,
            filled: true,
            fillColor: isEditing ? Colors.white : Colors.grey[200],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  void _showSnackbar(BuildContext context, String message, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }
}
