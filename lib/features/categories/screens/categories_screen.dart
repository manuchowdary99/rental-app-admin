import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/category_service.dart';
import '../models/category.dart';
import '../widgets/category_tile.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final CategoryService _service = CategoryService();
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // 🔁 Rebuild UI when text changes (fix Add button issue)
    _nameController.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    // 🔍 DEBUG (VERY IMPORTANT FOR WEB)
    print('👤 CURRENT USER: ${FirebaseAuth.instance.currentUser}');

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6EE),
      appBar: AppBar(
        title: const Text('Categories'),
        backgroundColor: const Color(0xFF781C2E),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ======================
          // ➕ ADD CATEGORY FORM
          // ======================
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Electronics, Furniture, Cars...',
                      prefixIcon: const Icon(Icons.category),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onSubmitted: (_) => _addCategory(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _nameController.text.trim().isEmpty
                      ? null
                      : _addCategory,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
          ),

          // ======================
          // 📋 CATEGORY LIST
          // ======================
          Expanded(
            child: StreamBuilder<List<Category>>(
              stream: _service.categoriesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                final categories = snapshot.data ?? [];

                if (categories.isEmpty) {
                  return const Center(
                    child: Text(
                      'No categories found',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return CategoryTile(
                      category: category,
                      onToggle: () => _service.toggleCategory(
                        category.id,
                        category.isActive,
                      ),
                      onDelete: () => _service.deleteCategory(category.id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ======================
  // ➕ ADD CATEGORY LOGIC
  // ======================
  void _addCategory() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    _service.addCategory(name);
    _nameController.clear();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
