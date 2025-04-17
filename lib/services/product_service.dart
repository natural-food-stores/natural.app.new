// services/product_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart'; // Adjust path if needed
import '../main.dart'; // Adjust path if needed

class ProductService {
  final _supabase = supabase;
  final String _productsTable = 'products';
  final String _storageBucket = 'productimages'; // Match actual bucket name

  // --- Existing fetchProducts method ---
  Future<List<Product>> fetchProducts() async {
    try {
      debugPrint('Fetching all products...'); // Added print
      final response = await _supabase
          .from(_productsTable)
          .select()
          .order('created_at', ascending: false);

      if (response == null) {
        debugPrint('Error fetching products: Supabase returned null');
        throw Exception('Failed to load products: Received null response');
      }
      final List<dynamic> dataList = response as List<dynamic>;
      debugPrint(
          'Raw data list length (all): ${dataList.length}'); // Added print

      final products = dataList
          .map((data) {
            if (data is Map<String, dynamic>) {
              return Product.fromJson(data);
            } else {
              debugPrint('Skipping invalid product data item: $data');
              return null;
            }
          })
          .whereType<Product>()
          .toList();
      debugPrint(
          'Parsed product list length (all): ${products.length}'); // Added print
      return products;
    } on PostgrestException catch (e) {
      debugPrint('PostgrestException fetching products: ${e.message}');
      debugPrint('Details: ${e.details}');
      debugPrint('Hint: ${e.hint}');
      throw Exception('Database error loading products: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected error fetching products: $e');
      throw Exception('Failed to load products: $e');
    }
  }

  // --- NEW: Method to fetch products by category ---
  Future<List<Product>> fetchProductsByCategory(String category) async {
    try {
      debugPrint('Fetching products for category: $category'); // Added print
      final response = await _supabase
          .from(_productsTable)
          .select()
          .eq('category', category) // Filter by category column
          .order('created_at', ascending: false);

      if (response == null) {
        debugPrint(
            'Error fetching products by category: Supabase returned null');
        throw Exception(
            'Failed to load products for category $category: Received null response');
      }
      final List<dynamic> dataList = response as List<dynamic>;
      debugPrint(
          'Raw data list length (category: $category): ${dataList.length}'); // Added print

      final products = dataList
          .map((data) {
            if (data is Map<String, dynamic>) {
              return Product.fromJson(data);
            } else {
              debugPrint('Skipping invalid product data item: $data');
              return null;
            }
          })
          .whereType<Product>()
          .toList();
      debugPrint(
          'Parsed product list length (category: $category): ${products.length}'); // Added print
      return products;
    } on PostgrestException catch (e) {
      debugPrint('PostgrestException fetching category products: ${e.message}');
      debugPrint('Details: ${e.details}');
      debugPrint('Hint: ${e.hint}');
      throw Exception('Database error loading category products: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected error fetching category products: $e');
      throw Exception('Failed to load products for category $category: $e');
    }
  }
  // -----------------------------------------------

  // --- Existing uploadImage method ---
  Future<String?> uploadImage(File imageFile, String fileName) async {
    // ... (uploadImage code remains the same) ...
    if (kIsWeb) {
      debugPrint(
          'uploadImage called on web, which is not supported with File type.');
      return null;
    }
    try {
      final String filePath =
          '${DateTime.now().millisecondsSinceEpoch}_${fileName.replaceAll(' ', '_')}';

      debugPrint('Uploading image to bucket: $_storageBucket, path: $filePath');

      await _supabase.storage.from(_storageBucket).upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final String publicUrl =
          _supabase.storage.from(_storageBucket).getPublicUrl(filePath);
      debugPrint('Image uploaded successfully. Public URL: $publicUrl');

      return publicUrl;
    } on StorageException catch (e) {
      debugPrint('StorageException uploading image: ${e.message}');
      debugPrint('StatusCode: ${e.statusCode}');
      debugPrint('Error: ${e.error}');
      return null;
    } catch (e) {
      debugPrint('Unexpected error uploading image: $e');
      return null;
    }
  }

  // --- Existing addProduct method ---
  Future<void> addProduct({
    required String name,
    String? description,
    required double price,
    required int quantity,
    required String category,
    String? imageUrl,
  }) async {
    // ... (addProduct code remains the same) ...
    try {
      final productData = {
        'name': name,
        'description': description,
        'price': price,
        'quantity': quantity,
        'category': category,
        'image_url': imageUrl,
      };
      debugPrint('Attempting to insert product: $productData');

      await _supabase.from(_productsTable).insert(productData);

      debugPrint('Product added successfully to $_productsTable');
    } on PostgrestException catch (e) {
      debugPrint('PostgrestException adding product: ${e.message}');
      debugPrint('Details: ${e.details}');
      debugPrint('Hint: ${e.hint}');
      throw Exception('Database error adding product: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected error adding product: $e');
      throw Exception('Failed to add product: $e');
    }
  }
}
