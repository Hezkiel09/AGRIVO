import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';

class FinancialDetailScreen extends StatefulWidget {
  final Map<String, dynamic> initialProfileData;

  const FinancialDetailScreen({super.key, required this.initialProfileData});

  @override
  State<FinancialDetailScreen> createState() => _FinancialDetailScreenState();
}

class _FinancialDetailScreenState extends State<FinancialDetailScreen> {
  bool _isLoading = false;
  late int _saldo;

  @override
  void initState() {
    super.initState();
    _saldo = widget.initialProfileData['saldo'] ?? 0;
    _refreshProfile();
  }

  Future<void> _refreshProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await ApiService.getProfile();
      if (profile != null) {
        setState(() {
          _saldo = profile['saldo'] ?? 0;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatCurrency(int amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  void _showTopUpDialog() {
    final TextEditingController _amountController = TextEditingController();
    bool _isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Top Up Saldo', style: TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Masukkan nominal top up:'),
                const SizedBox(height: 12),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixText: 'Rp ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _quickAmountBtn('50.000', 50000, _amountController),
                    _quickAmountBtn('100.000', 100000, _amountController),
                    _quickAmountBtn('500.000', 500000, _amountController),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: _isSubmitting ? null : () => Navigator.pop(ctx),
                child: const Text('Batal', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        final amtStr = _amountController.text.replaceAll('.', '').replaceAll(',', '');
                        final amount = int.tryParse(amtStr) ?? 0;
                        if (amount < 10000) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Minimal top up Rp 10.000')),
                          );
                          return;
                        }

                        setStateDialog(() => _isSubmitting = true);
                        final success = await ApiService.topUpSaldo(amount);
                        
                        if (mounted) {
                          Navigator.pop(ctx);
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Berhasil top up ${_formatCurrency(amount)}'),
                                backgroundColor: const Color(0xFF1B4F1E),
                              ),
                            );
                            _refreshProfile();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Gagal top up, silakan coba lagi')),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B4F1E)),
                child: _isSubmitting 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Top Up', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _quickAmountBtn(String label, int value, TextEditingController controller) {
    return InkWell(
      onTap: () {
        controller.text = value.toString();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F8EE),
          border: Border.all(color: const Color(0xFFC8E6C9)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF1B4F1E), fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Keuangan Saya', style: TextStyle(color: Color(0xFF1B4F1E), fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProfile,
        color: const Color(0xFF1B4F1E),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Saldo Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B4F1E), Color(0xFF2E7D32)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF1B4F1E).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Saldo Aktif',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      Icon(Icons.account_balance_wallet, color: Colors.white.withOpacity(0.8), size: 24),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_isLoading)
                    const CircularProgressIndicator(color: Colors.white)
                  else
                    Text(
                      _formatCurrency(_saldo),
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showTopUpDialog,
                          icon: const Icon(Icons.add, size: 18, color: Color(0xFF1B4F1E)),
                          label: const Text('Top Up Saldo', style: TextStyle(color: Color(0xFF1B4F1E), fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Fitur penarikan dana akan segera hadir!')),
                            );
                          },
                          icon: const Icon(Icons.arrow_upward, size: 18, color: Colors.white),
                          label: const Text('Tarik Dana', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white70),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Dummy History Section
            const Text(
              'Riwayat Transaksi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 16),
            
            _buildHistoryItem(Icons.arrow_downward, 'Top Up Saldo', 'Berhasil', '+ Rp 100.000', '12 Okt 2023, 14:30', true),
            _buildHistoryItem(Icons.shopping_cart, 'Pembelian Sayur', 'Berhasil', '- Rp 25.000', '10 Okt 2023, 09:15', false),
            _buildHistoryItem(Icons.arrow_downward, 'Top Up Saldo', 'Berhasil', '+ Rp 50.000', '01 Okt 2023, 11:00', true),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(IconData icon, String title, String status, String amount, String date, bool isPositive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isPositive ? const Color(0xFFF1F8EE) : const Color(0xFFFFF0F0),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: isPositive ? const Color(0xFF1B4F1E) : const Color(0xFFE53935), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 4),
                Text(date, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isPositive ? const Color(0xFF1B4F1E) : const Color(0xFFE53935),
                ),
              ),
              const SizedBox(height: 4),
              Text(status, style: const TextStyle(fontSize: 11, color: Colors.green)),
            ],
          ),
        ],
      ),
    );
  }
}
