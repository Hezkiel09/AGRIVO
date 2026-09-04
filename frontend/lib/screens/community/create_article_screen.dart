import 'package:agrivo/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;

class CreateArticleScreen extends StatefulWidget {
  const CreateArticleScreen({Key? key}) : super(key: key);

  @override
  State<CreateArticleScreen> createState() => _CreateArticleScreenState();
}

class _CreateArticleScreenState extends State<CreateArticleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _refSourceController = TextEditingController();
  final _refUrlController = TextEditingController();

  String? _selectedCategory;
  XFile? _imageFile;
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Pertanian',
    'Perkebunan',
    'Peternakan',
    'UMKM',
    'Opini',
    'Riset',
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
    final text = _contentController.text;
    final selection = _contentController.selection;

    if (selection.isValid && selection.start >= 0 && selection.end >= 0) {
      final selectedText = text.substring(selection.start, selection.end);
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        '$startTag$selectedText$endTag',
      );

      _contentController.value = TextEditingValue(
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
      _contentController.value = TextEditingValue(
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pilih kategori artikel!')));
      return;
    }
    if (_imageFile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unggah thumbnail wajib!')));
      return;
    }

    setState(() => _isSubmitting = true);

    bool success = await ApiService.createBerita(
      _titleController.text,
      _selectedCategory!,
      _contentController.text,
      _refSourceController.text,
      _refUrlController.text,
      _imageFile,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Artikel berhasil diajukan!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Gagal mengajukan artikel. Pastikan Anda sudah login.',
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
          'Ajukan Artikel',
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
              // Header Image
              _buildSectionCard(
                title: 'Header',
                icon: Icons.image,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      border: Border.all(
                        color: Colors.grey.shade400,
                        style: BorderStyle.none,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _imageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: kIsWeb
                                ? Image.network(
                                    _imageFile!.path,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    File(_imageFile!.path),
                                    fit: BoxFit.cover,
                                  ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.upload_file,
                                color: Colors.green,
                                size: 30,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Unggah Thumbnail *',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Format JPG/JPEG, PNG maks 2MB',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              // Identitas Artikel
              _buildSectionCard(
                title: 'Identitas Artikel',
                icon: Icons.article,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Judul Artikel *'),
                    TextFormField(
                      controller: _titleController,
                      validator: (val) => val != null && val.length < 10
                          ? 'Minimal 10 karakter'
                          : null,
                      decoration: InputDecoration(
                        hintText: 'Masukkan judul (Minimal 10 karakter)...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('Kategori *'),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        hintText: 'Pilih Kategori',
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
                  ],
                ),
              ),

              const SizedBox(height: 16),
              // Isi Artikel
              _buildSectionCard(
                title: 'Isi Artikel *',
                icon: Icons.notes,
                child: Container(
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
                              onPressed: () => _insertFormat('<h2>', '</h2>'),
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
                            Container(width: 1, height: 20, color: Colors.grey),
                            IconButton(
                              icon: const Icon(Icons.format_list_bulleted),
                              onPressed: () =>
                                  _insertFormat('<ul>\n  <li>', '</li>\n</ul>'),
                              tooltip: 'Bullet List',
                            ),
                            IconButton(
                              icon: const Icon(Icons.link),
                              onPressed: () =>
                                  _insertFormat('<a href="URL">', '</a>'),
                              tooltip: 'Link',
                            ),
                            IconButton(
                              icon: const Icon(Icons.image),
                              onPressed: () =>
                                  _insertFormat('<img src="URL" alt="', '">'),
                              tooltip: 'Image',
                            ),
                          ],
                        ),
                      ),
                      TextFormField(
                        controller: _contentController,
                        maxLines: 8,
                        validator: (val) => val != null && val.length < 30
                            ? 'Minimal 30 karakter'
                            : null,
                        decoration: const InputDecoration(
                          hintText: 'Tuliskan riset, opini, atau pengalamanmu di sini (Minimal 300 kata)...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              // Referensi
              _buildSectionCard(
                title: 'Referensi dan Lampiran',
                icon: Icons.library_books,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Sumber Referensi *'),
                    TextFormField(
                      controller: _refSourceController,
                      validator: (val) => val != null && val.isEmpty
                          ? 'Sumber referensi tidak boleh kosong'
                          : null,
                      decoration: InputDecoration(
                        hintText: 'Masukkan judul link URL atau Sitasi Buku',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('Link Video YouTube / Link Gambar (Opsional)'),
                    TextFormField(
                      controller: _refUrlController,
                      decoration: InputDecoration(
                        hintText: 'https://...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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
                        'Ajukan Artikel',
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

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
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
}
