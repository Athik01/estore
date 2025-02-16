import 'dart:convert';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController typeController = TextEditingController();
  final TextEditingController expiryDateController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  List<Map<String, String>> sizeVariants = [];
  bool hasExpiryDate = false;
  bool hasSizeVariants = false;
  File? _imageFile;

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);  // Convert XFile to File
        });
      } else {
        _showSnackbar(context, "No image selected.", false);
      }
    } catch (e) {
      _showSnackbar(context, "Error picking image: $e", false);
      print(e);
    }
  }


  void addSizeVariant() {
    setState(() {
      sizeVariants.add({"size": "", "price": ""});
    });
  }

  void removeSizeVariant(int index) {
    setState(() {
      sizeVariants.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add New Product", style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white)),
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,color: Colors.white,),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼️ Image Picker with Improved UI
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid, width: 2),
                  image: _imageFile != null
                      ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                      : null,
                ),
                child: _imageFile == null
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                    SizedBox(height: 5),
                    Text("Tap to upload image", style: TextStyle(color: Colors.grey)),
                  ],
                )
                    : Container(
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Center(
                    child: Icon(Icons.edit, size: 50, color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildInputField(nameController, "Product Name", Icons.shopping_bag),

            // 🔄 Product Type
            _buildInputField(typeController, "Product Type (e.g., Milk, Laptop, Shoes)", Icons.category),

            // 📅 Has Expiry Date (Dropdown)
            _buildDropdown<bool>("Has Expiry Date?", Icons.info, hasExpiryDate, (value) {
              setState(() {
                hasExpiryDate = value ?? false;
              });
            }, [
              DropdownMenuItem(value: true, child: Text("Yes")),
              DropdownMenuItem(value: false, child: Text("No")),
            ]),

            // 📅 Expiry Date Field (If applicable)
            if (hasExpiryDate) _buildInputField(expiryDateController, "Expiry Date (DD/MM/YYYY)", Icons.calendar_today),

            // 📏 Has Size Variants (Dropdown)
            _buildDropdown<bool>("Has Size Variants?", Icons.straighten, hasSizeVariants, (value) {
              setState(() {
                hasSizeVariants = value ?? false;
              });
            }, [
              DropdownMenuItem(value: true, child: Text("Yes")),
              DropdownMenuItem(value: false, child: Text("No")),
            ]),

            // 💰 Price (Only if no size variants)
            if (!hasSizeVariants) ...[
              _buildInputField(priceController, "Price (Rs.)", Icons.currency_rupee, isNumeric: true),
              _buildInputField(quantityController, "Quantity (Units)", Icons.format_list_numbered, isNumeric: true),
            ],
            // 📏 Size Variants (Only if applicable)
            if (hasSizeVariants)
              Column(
                children: [
                  for (int i = 0; i < sizeVariants.length; i++)
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            // 🏷️ Size Input
                            Expanded(
                              child: _buildInputField(
                                null,
                                "Size",
                                Icons.straighten,
                                onChanged: (value) {
                                  sizeVariants[i]["size"] = value;
                                },
                              ),
                            ),
                            const SizedBox(width: 10),

                            // 💰 Price Input
                            Expanded(
                              child: _buildInputField(
                                null,
                                "Price (Rs.)",
                                Icons.currency_rupee,
                                isNumeric: true,
                                onChanged: (value) {
                                  sizeVariants[i]["price"] = value;
                                },
                              ),
                            ),
                            const SizedBox(width: 10),

                            // 📦 Quantity Input
                            Expanded(
                              child: _buildInputField(
                                null,
                                "Quantity",
                                Icons.shopping_cart,
                                isNumeric: true,
                                onChanged: (value) {
                                  sizeVariants[i]["quantity"] = value;
                                },
                              ),
                            ),

                            // 🗑️ Delete Button
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => removeSizeVariant(i),
                            ),
                          ],
                        ),
                      ),
                    ),

                  SizedBox(height: 5,),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text("Add Size Variant", style: TextStyle(color: Colors.white)),
                    onPressed: addSizeVariant,
                  ),
                ],
              ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: () {
            // TODO: Implement product saving logic
            _addProductToFirestore();
            Navigator.pop(context);
          },
          child: const Text("Add Product", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

// 🔥 Helper Functions for Clean UI
  Widget _buildInputField(
      TextEditingController? controller,
      String label,
      IconData icon, {
        bool isNumeric = false,
        Function(String)? onChanged,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        onChanged: onChanged,
      ),
    );
  }
  void _addProductToFirestore() async {
    if (nameController.text.isEmpty || typeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Product Name and Type are required!")),
      );
      return;
    }

    String? base64Image;
    if (_imageFile != null) {
      List<int> imageBytes = await _imageFile!.readAsBytes();
      base64Image = base64Encode(imageBytes);
    }

    Map<String, dynamic> productData = {
      "name": nameController.text.trim(),
      "type": typeController.text.trim(),
      "hasExpiryDate": hasExpiryDate,
      "expiryDate": hasExpiryDate ? expiryDateController.text.trim() : null,
      "hasSizeVariants": hasSizeVariants,
      "imageBase64": base64Image, // Store base64-encoded image
    };

    if (hasSizeVariants) {
      productData["sizeVariants"] = sizeVariants.map((variant) {
        return {
          "size": variant["size"] ?? "",
          "price": variant["price"] ?? "",
          "quantity": variant["quantity"] ?? "",
        };
      }).toList();
    } else {
      productData["price"] = priceController.text.trim();
      if (quantityController.text.trim().isNotEmpty) {
        productData["quantity"] = quantityController.text.trim();
      }
    }

    try {
      DocumentReference docRef = await FirebaseFirestore.instance.collection("products").add(productData);

      // Generate QR Code based on the Firestore document ID
      String qrCodeBase64 = await _generateQRCode(docRef.id);

      // Update the product with the QR code
      await docRef.update({"qrcode": qrCodeBase64});

      _showSnackbar(context, "Product added successfully!", true);
      Navigator.pop(context);
    } catch (e) {
      _showSnackbar(context, "Error adding product: $e", false);
    }
  }
  Future<String> _generateQRCode(String productId) async {
    try {
      final qrValidationResult = QrValidator.validate(
        data: productId,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.H,
      );

      if (qrValidationResult.status == QrValidationStatus.valid) {
        final qrCode = qrValidationResult.qrCode!;
        final qrPainter = QrPainter.withQr(
          qr: qrCode,
          color: const Color(0xFF000000),
          gapless: true,
        );

        // Render QR code to an image
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        qrPainter.paint(canvas, const Size(200, 200));
        final picture = recorder.endRecording();
        final image = await picture.toImage(200, 200);
        ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

        if (byteData != null) {
          Uint8List imageBytes = byteData.buffer.asUint8List();
          return base64Encode(imageBytes); // Convert to Base64
        }
      }
    } catch (e) {
      print("QR Code Generation Error: $e");
    }
    throw Exception("Failed to generate QR Code");
  }
  void _showSnackbar(BuildContext context, String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 3),
        elevation: 6.0,
      ),
    );
  }

  Widget _buildDropdown<T>(
      String label,
      IconData icon,
      T value,
      Function(T?) onChanged,
      List<DropdownMenuItem<T>> items,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4), // More padding for better spacing
      child: Material(
        elevation: 2, // Adds a subtle shadow effect
        borderRadius: BorderRadius.circular(12), // Smooth rounded edges
        child: DropdownButtonFormField<T>(
          value: value,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500), // Improved text style
            prefixIcon: Icon(icon, color: Colors.green[700]), // Updated icon color
            filled: true,
            fillColor: Colors.white, // Bright background for contrast
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16), // Comfortable input spacing
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.green.shade300, width: 1.5), // Green border for a fresh look
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.green.shade200, width: 1), // Lighter green border
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.green.shade700, width: 2), // Darker border when focused
            ),
          ),
          dropdownColor: Colors.white, // Ensures dropdown background matches UI theme
          icon: const Icon(Icons.arrow_drop_down, size: 30, color: Colors.green), // Enhances dropdown visibility
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }


}
