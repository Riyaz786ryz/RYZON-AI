import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  static const String _baseUrl = String.fromEnvironment('RYZONE_API_BASE_URL');
  late Future<Map<String, dynamic>> _walletFuture;
  late final Razorpay _razorpay;
  bool _purchasing = false;
  int _creditsBeforePayment = 0;
  int _expectedCredits = 0;

  @override
  void initState() {
    super.initState();
    _walletFuture = _loadWallet();
    _razorpay = Razorpay()
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess)
      ..on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError)
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<Map<String, dynamic>> _loadWallet() async {
    if (_baseUrl.trim().isEmpty) {
      throw Exception('Wallet server is not connected yet. Deploy the secure backend first.');
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Please sign in with Google first.');
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) throw Exception('Could not get a secure sign-in token.');
    final root = _baseUrl.replaceFirst(RegExp(r'/+$'), '');
    final headers = {'Authorization': 'Bearer ' + token};
    final responses = await Future.wait([
      http.get(Uri.parse(root + '/v1/wallet'), headers: headers).timeout(const Duration(seconds: 20)),
      http.get(Uri.parse(root + '/v1/wallet/transactions'), headers: headers).timeout(const Duration(seconds: 20)),
    ]);
    if (responses.any((r) => r.statusCode != 200)) {
      final failed = responses.firstWhere((r) => r.statusCode != 200);
      throw Exception('Could not load wallet information (' + failed.statusCode.toString() + ').');
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

  Future<void> _buyCredits(String packageId, int credits) async {
    if (_purchasing) return;
    if (_baseUrl.trim().isEmpty) {
      _showMessage('Secure payment server is not connected yet.');
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('Please sign in with Google first.');
      return;
    }
    setState(() => _purchasing = true);
    try {
      final token = await user.getIdToken();
      if (token == null || token.isEmpty) throw Exception('Secure sign-in token unavailable.');
      final root = _baseUrl.replaceFirst(RegExp(r'/+$'), '');
      final response = await http.post(
        Uri.parse(root + '/v1/payments/razorpay/order'),
        headers: {'Authorization': 'Bearer ' + token, 'content-type': 'application/json'},
        body: jsonEncode({'packageId': packageId}),
      ).timeout(const Duration(seconds: 25));
      if (response.statusCode != 200) {
        throw Exception('Could not start payment (' + response.statusCode.toString() + ').');
      }
      final order = jsonDecode(response.body);
      if (order is! Map<String, dynamic> || order['ok'] != true ||
          order['keyId'] is! String || order['orderId'] is! String ||
          order['amount'] is! int) {
        throw Exception('Payment server returned an invalid order.');
      }
      _creditsBeforePayment = await _currentCredits();
      _expectedCredits = credits;
      _razorpay.open({
        'key': order['keyId'],
        'amount': order['amount'],
        'currency': order['currency'] ?? 'INR',
        'name': 'RYZONE',
        'description': order['credits'].toString() + ' RYZONE Credits',
        'order_id': order['orderId'],
        'prefill': {'email': user.email ?? ''},
        'retry': {'enabled': true, 'max_count': 2},
      });
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
      if (mounted) setState(() => _purchasing = false);
    }
  }

  Future<int> _currentCredits() async {
    final data = await _loadWallet();
    final wallet = data['wallet'] as Map<String, dynamic>;
    return (wallet['credits'] as num?)?.toInt() ?? 0;
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // Client callbacks never add credits. The signed server webhook does that.
    for (var attempt = 0; attempt < 8; attempt++) {
      await Future<void>.delayed(const Duration(seconds: 2));
      try {
        final data = await _loadWallet();
        final wallet = data['wallet'] as Map<String, dynamic>;
        final credits = (wallet['credits'] as num?)?.toInt() ?? 0;
        if (credits >= _creditsBeforePayment + _expectedCredits) {
          if (!mounted) return;
          setState(() {
            _walletFuture = Future.value(data);
            _purchasing = false;
          });
          _showMessage('Payment verified. ' + _expectedCredits.toString() + ' credits added!');
          return;
        }
      } catch (_) {
        // Retry briefly while the signed gateway webhook is delivered.
      }
    }
    if (!mounted) return;
    setState(() {
      _walletFuture = _loadWallet();
      _purchasing = false;
    });
    _showMessage('Payment submitted. Credits appear after secure verification; refresh shortly.');
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) setState(() => _purchasing = false);
    _showMessage('Payment was not completed. No credits were added.');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _showMessage('External wallet selected. Complete payment to receive credits.');
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _money(dynamic value) {
    final paise = value is num ? value.toInt() : 0;
    return '₹' + (paise / 100).toStringAsFixed(2);
  }

  String _titleForType(String type) {
    switch (type) {
      case 'topup':
        return 'Wallet recharge';
      case 'credit_topup':
        return 'Credits purchased';
      case 'reserve':
        return 'AI job amount held';
      case 'debit':
        return 'AI service charge';
      case 'release':
        return 'Amount released';
      default:
        return 'Wallet transaction';
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
                    const Text('AVAILABLE CREDITS', style: TextStyle(letterSpacing: 1, color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 8),
                    Text(((wallet['credits'] as num?)?.toInt() ?? 0).toString(), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('RYZONE AI Credits', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text('Buy Credits', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _packageCard('Starter', '100 Credits', '₹299', 'starter', 100, 'For trying RYZONE AI'),
              _packageCard('Creator', '200 Credits', '₹549', 'creator', 200, 'For regular creators', popular: true),
              _packageCard('Pro Creator', '500 Credits', '₹1,299', 'pro', 500, 'For frequent creators'),
              const SizedBox(height: 8),
              const Text('Credits are added only after the payment provider confirms the payment securely.', style: TextStyle(color: Colors.white60, fontSize: 12)),
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
                  final incoming = type == 'topup' || type == 'release' || type == 'credit_topup';
                  final credits = (item['credits'] as num?)?.toInt() ?? 0;
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
                        type == 'credit_topup' ? '+' + credits.toString() + ' credits' : (incoming ? '+' : '-') + _money(item['amountPaise']),
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

  Widget _packageCard(String title, String creditsLabel, String price, String packageId,
      int credits, String subtitle, {bool popular = false}) => Card(
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (popular) const Text('POPULAR', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 11)),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(price, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 4),
        Text(creditsLabel, style: const TextStyle(fontSize: 18, color: Color(0xFFC8B6FF), fontWeight: FontWeight.w700)),
        Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 10),
        SizedBox(width: double.infinity, child: FilledButton(
          onPressed: _purchasing ? null : () => _buyCredits(packageId, credits),
          child: Text(_purchasing ? 'Please wait...' : 'Buy ' + creditsLabel),
        )),
      ]),
    ),
  );
}
