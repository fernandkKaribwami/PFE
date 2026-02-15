import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'feed_screen.dart';

// ignore: constant_identifier_names
const String API_URL = 'http://localhost:5000';

class VerifyEmailScreen extends StatefulWidget {
  final String email;
  final String? serverCode; // for dev/testing
  const VerifyEmailScreen({super.key, required this.email, this.serverCode});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final codeCtrl = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.serverCode != null) {
      codeCtrl.text = widget.serverCode!;
    }
  }

  @override
  void dispose() {
    codeCtrl.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (codeCtrl.text.isEmpty) return;
    setState(() => isLoading = true);
    try {
      final res = await http
          .post(
            Uri.parse('$API_URL/auth/verify-email'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': widget.email, 'code': codeCtrl.text}),
          )
          .timeout(const Duration(seconds: 10));

      setState(() => isLoading = false);

      if (res.statusCode == 200) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const FeedScreen(token: '')),
        );
      } else {
        final err = jsonDecode(res.body);
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: ${err['message']}')));
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vérifier l\'email')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Entrez le code envoyé à votre adresse email'),
            const SizedBox(height: 12),
            TextField(
              controller: codeCtrl,
              decoration: const InputDecoration(
                labelText: 'Code de vérification',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: isLoading ? null : submit,
              child: isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Vérifier'),
            ),
          ],
        ),
      ),
    );
  }
}
