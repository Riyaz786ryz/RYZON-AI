import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  static const String _baseUrl = String.fromEnvironment('RYZONE_API_BASE_URL');
  late Future<Map<String, dynamic>> _walletFuture;

  @override
  void initState() {
    super.initState();
    _walletFuture = _loadWallet();
  }

  Future<Map<String, dynamic>> _loadWallet() async {
    if (_baseUrl.trim().isEmpty) {
      throw Exception('Wallet server is not connected yet. It will be available after the secure backend is deployed.');
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Please sign in with Google first.');
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) throw Exception('Could not get a secure sign-in token.');
    final root = _baseUrl.replaceFirst(RegExp(r'/+$'), '');
    final headers = {'Authorization': 'Bearer $token'};
    final responses = await Future.wait([
      http.get(Uri.parse('$root/v1/wallet'), headers: headers).timeout(const Duration(seconds: 20)),
      http.get(Uri.parse('$root/v1/wallet/transactions'), headers: headers).timeout(const Duration(seconds: 20)),
    ]);
    if (responses.any((r) => r.statusCode != 200)) {
      final failed = responses.firstWhere((r) => r.statusCode != 200);
      throw Exception('Could not load wallet information (${failed.statusCode}).');
    }
    final walletPayload = jsonDecode(responses[0].body);
    final historyPayload = jsonDecode(responses[1].body);
    if (walletPayload is! Map<String, dynamic> || walletPayload['ok'] != true ||
        historyPayload is! Map<String, dynamic> || historyPayload['ok'] != true) {
      throw Exception('The wallet server returned an invalid response.');
    }
    return {
      'wallet': walletPayload['wallet'] as Map<String, dynamic>,
      'transactions': (historyPayload['transactions'] as List<dynamic>? ?? const []),
    };
  }

  String _money(dynamic value) {
    final paise = value is int ? value : 0;
    return '₹${(paise / 100).toStringAsFixed(2)}';
  }

  String _titleForType(String type) {
    switch (type) {
      case 'topup': return 'Wallet recharge';
      case 'reserve': return 'AI job amount held';
      case 'debit': return 'AI service charge';
      case 'release': return 'Amount released';
      default: return 'Wallet transaction';
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('My Wallet'),
      actions: [
        IconButton(
          tooltip: 'Refresh wallet',
          onPressed: () => setState(() => _walletFuture = _loadWallet()),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: SafeArea(
      child: FutureBuilder<Map<String, dynamic>>(
        future: _walletFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined, size: 48, color: Color(0xFFC8B6FF)),
                    const SizedBox(height: 14),
                    const Text('Wallet is not connected', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(snapshot.error.toString().replaceFirst('Exception: ', ''), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _walletFuture = _loadWallet()),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            );
          }
          final data = snapshot.data!;
          final wallet = data['wallet'] as Map<String, dynamic>;
          final transactions = data['transactions'] as List<dynamic>;
          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF49317E), Color(0xFF242044)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('AVAILABLE BALANCE', style: TextStyle(letterSpacing: 1, color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 8),
                    Text(_money(wallet['availablePaise']), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _amountTile('Total balance', _money(wallet['balancePaise']))),
                        Expanded(child: _amountTile('Reserved', _money(wallet['reservedPaise']))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    children: const [
                      Icon(Icons.lock_outline, color: Color(0xFFC8B6FF)),
                      SizedBox(width: 10),
                      Expanded(child: Text('Wallet recharge will be enabled after payment gateway verification is configured. Never send money to an unofficial account.')),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Recent transactions', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (transactions.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('No wallet transactions yet.', style: TextStyle(color: Colors.white60))),
                )
              else
                ...transactions.map((raw) {
                  final item = raw as Map<String, dynamic>;
                  final type = item['type']?.toString() ?? '';
                  final incoming = type == 'topup' || type == 'release';
                  final date = DateTime.tryParse(item['createdAt']?.toString() ?? '');
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF343044),
                        child: Icon(incoming ? Icons.south_west : Icons.north_east, color: incoming ? Colors.greenAccent : Colors.orangeAccent),
                      ),
                      title: Text(_titleForType(type)),
                      subtitle: Text(date == null ? 'Date unavailable' : date.toLocal().toString().substring(0, 16)),
                      trailing: Text(
                        '${incoming ? '+' : '-'}${_money(item['amountPaise'])}',
                        style: TextStyle(fontWeight: FontWeight.bold, color: incoming ? Colors.greenAccent : Colors.orangeAccent),
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    ),
  );

  Widget _amountTile(String label, String amount) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
      const SizedBox(height: 3),
      Text(amount, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
    ],
  );
}
