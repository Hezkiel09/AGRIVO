import 'package:agrivo/services/api_service.dart';
import 'package:agrivo/screens/create_community_screen.dart';
import 'package:agrivo/screens/article_detail_screen.dart';
import 'package:agrivo/screens/community_chat_screen.dart';
import 'package:flutter/material.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({Key? key}) : super(key: key);

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  List<dynamic> _beritaList = [];
  List<dynamic> _komunitasList = [];
  List<dynamic> _myCommunitiesList = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    // Ambil data secara paralel dari backend
    final results = await Future.wait([
      ApiService.getBerita(),
      ApiService.getKomunitas(),
      ApiService.getMyCommunities(),
    ]);

    if (mounted) {
      setState(() {
        _beritaList = results[0];
        _komunitasList = results[1];
        _myCommunitiesList = results[2];
        _isLoading = false;
      });
    }
  }

  List<dynamic> get _filteredBerita {
    if (_searchQuery.isEmpty) return _beritaList.take(5).toList();
    return _beritaList.where((item) {
      String title = item['title'] ?? '';
      return title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  List<dynamic> get _filteredKomunitas {
    if (_searchQuery.isEmpty) {
      // Sembunyikan yang sudah bergabung dan batasi 5
      return _komunitasList
          .where((item) => item['is_joined'] != true)
          .take(5)
          .toList();
    }
    return _komunitasList.where((item) {
      String name = item['name'] ?? '';
      return name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _showMyCommunities() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Komunitas Saya',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: _myCommunitiesList.isEmpty
                    ? const Text('Anda belum bergabung ke komunitas mana pun.')
                    : ListView.builder(
                        itemCount: _myCommunitiesList.length,
                        itemBuilder: (context, index) {
                          final item = _myCommunitiesList[index];
                          String name = item['name'] ?? 'K';
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green,
                              child: Text(
                                name.substring(0, 1).toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(name),
                            onTap: () {
                              Navigator.pop(context); // Tutup bottom sheet
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      CommunityChatScreen(community: item),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAEF), // Warna latar hijau sangat muda
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: const Color(0xFF1B4F1E),
              child: const Icon(Icons.person, color: Colors.white),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showMyCommunities,
        backgroundColor: const Color(0xFF1B4F1E),
        child: const Icon(Icons.chat_bubble, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Cari Komunitas atau Artikel...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // --- BAGIAN TERBARU (BERITA) ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Artikel Terbaru',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B4F1E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_filteredBerita.isEmpty)
                      const Text('Artikel tidak ditemukan.')
                    else
                      SizedBox(
                        height: 220,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _filteredBerita.length,
                          itemBuilder: (context, index) {
                            final item = _filteredBerita[index];
                            return _buildBeritaCard(item);
                          },
                        ),
                      ),

                    const SizedBox(height: 32),

                    // --- BAGIAN KOMUNITAS ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Komunitas',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B4F1E),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const CreateCommunityScreen(),
                              ),
                            ).then((_) => _fetchData());
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B4F1E),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Buat Baru',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_filteredKomunitas.isEmpty)
                      const Text('Komunitas tidak ditemukan.')
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _filteredKomunitas.length,
                        itemBuilder: (context, index) {
                          final item = _filteredKomunitas[index];
                          return _buildKomunitasCard(item);
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBeritaCard(dynamic item) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArticleDetailScreen(article: item),
          ),
        );
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                color: const Color(0xFFF1F8EE),
                height: 120,
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                child: Image.asset(
                  'assets/icon/agrivo_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                item['title'] ?? 'Tanpa Judul',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKomunitasCard(dynamic item) {
    String name = item['name'] ?? 'Komunitas';
    String initial =
        name.isNotEmpty ? name.substring(0, 2).toUpperCase() : 'KO';
    bool isJoined = item['is_joined'] == true;

    // Generate warna acak berdasarkan inisial agar unik
    int hash = initial.hashCode;
    Color avatarColor = Colors.primaries[hash % Colors.primaries.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: avatarColor.withOpacity(0.8),
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (isJoined) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CommunityChatScreen(community: item),
                          ),
                        );
                      } else {
                        setState(() => _isLoading = true);
                        bool success = await ApiService.joinCommunity(item['id']);
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Berhasil gabung ke $name!')),
                          );
                          _fetchData(); // Refresh UI to remove it from list and add to my communities
                        } else {
                          setState(() => _isLoading = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Gagal bergabung.')),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B4F1E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(isJoined ? 'Lihat' : 'Gabung'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
