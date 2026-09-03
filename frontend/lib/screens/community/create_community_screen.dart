import 'package:agrivo/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;

class CreateCommunityScreen extends StatefulWidget {
  const CreateCommunityScreen({Key? key}) : super(key: key);

  @override
  State<CreateCommunityScreen> createState() => _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends State<CreateCommunityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedCategory;
  String _privacy = 'Publik';
  XFile? _imageFile;
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Pertanian',
    'Perkebunan',
    'Peternakan',
    'UMKM',
    'Teknologi Tani',
  ];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() => _imageFile = pickedFile);
    }
  }

  void _insertFormat(String startTag, String endTag) {
    final text = _descriptionController.text;
    final selection = _descriptionController.selection;

    if (selection.isValid && selection.start >= 0 && selection.end >= 0) {
      final selectedText = text.substring(selection.start, selection.end);
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        '$startTag$selectedText$endTag',
      );

      _descriptionController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset:
              selection.start +
              startTag.length +
              selectedText.length +
              endTag.length,
        ),
      );
    } else {
      final newText = text + startTag + endTag;
      _descriptionController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: newText.length - endTag.length,
        ),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori komunitas!')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    bool success = await ApiService.createKomunitas(
      _nameController.text,
      _selectedCategory!,
      _privacy,
      _descriptionController.text,
      _imageFile,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Komunitas berhasil dibuat!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Gagal membuat komunitas. Pastikan Anda sudah login.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAEF),
      appBar: AppBar(
        title: const Text(
          'Komunitas',
          style: TextStyle(
            color: Color(0xFF1B4F1E),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1B4F1E)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFF4C5E48),
                    backgroundImage: _imageFile != null
                        ? (kIsWeb
                                  ? NetworkImage(_imageFile!.path)
                                  : FileImage(File(_imageFile!.path)))
                              as ImageProvider
                        : null,
                    child: _imageFile == null
                        ? const Icon(
                            Icons.camera_alt,
                            size: 40,
                            color: Colors.white70,
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Nama Komunitas *'),
                    TextFormField(
                      controller: _nameController,
                      validator: (val) => val != null && val.length < 10
                          ? 'Minimal 10 karakter'
                          : null,
                      decoration: InputDecoration(
                        hintText: 'Masukan nama (minimal 10 karakter)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildLabel('Kategori Komunitas *'),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        hintText: 'Pilih Kategori Komunitas',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: _categories
                          .map(
                            (cat) =>
                                DropdownMenuItem(value: cat, child: Text(cat)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedCategory = val),
                    ),
                    const SizedBox(height: 20),

                    _buildLabel('Privasi *'),
                    Row(
                      children: [
                        _buildPrivacyButton('Publik'),
                        const SizedBox(width: 12),
                        _buildPrivacyButton('Private'),
                      ],
                    ),
                    const SizedBox(height: 20),

                    _buildLabel('Deskripsi'),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          // Fake Toolbar
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade300),
                              ),
                              color: Colors.grey.shade100,
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.format_size),
                                  onPressed: () =>
                                      _insertFormat('<h2>', '</h2>'),
                                  tooltip: 'Heading 2',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.format_bold),
                                  onPressed: () => _insertFormat('<b>', '</b>'),
                                  tooltip: 'Bold',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.format_italic),
                                  onPressed: () => _insertFormat('<i>', '</i>'),
                                  tooltip: 'Italic',
                                ),
                                Container(
                                  width: 1,
                                  height: 20,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 5,
                            decoration: const InputDecoration(
                              hintText: 'Tuliskan deskripsi komunitas disini\n(maksimal 100 kata)',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F681A),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Buat Komunitas',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF4C5E48),
        ),
      ),
    );
  }

  Widget _buildPrivacyButton(String title) {
    bool isSelected = _privacy == title;
    return Expanded(
      child: OutlinedButton(
        onPressed: () => setState(() => _privacy = title),
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? const Color(0xFF0F681A) : Colors.white,
          side: BorderSide(
            color: isSelected ? const Color(0xFF0F681A) : Colors.grey,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          title,
          style: TextStyle(color: isSelected ? Colors.white : Colors.black87),
        ),
      ),
    );
  }
}
