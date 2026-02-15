// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:io' show File;
import 'screens/feed_screen.dart';
import 'screens/create_post_screen.dart';
import 'screens/verify_email_screen.dart';

// Configuration API
// ignore: constant_identifier_names
const String API_URL = 'http://localhost:5000';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'USMBA Social',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF003366),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _ctrl.forward();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AuthScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.lerp(
                    const Color(0xFF003366),
                    Colors.blueAccent,
                    _ctrl.value,
                  )!,
                  Colors.white,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Opacity(
                opacity: _ctrl.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.school, size: 96, color: Colors.white),
                    const SizedBox(height: 12),
                    const Text(
                      'USMBA Social',
                      style: TextStyle(
                        fontSize: 28,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  final nomCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final bioCtrl = TextEditingController();
  String? selectedFaculty;
  bool isLoading = false;
  XFile? avatarFile;
  final ImagePicker picker = ImagePicker();

  final faculties = [
    'Faculté des Sciences',
    'Faculté des Lettres',
    'École Nationale d\'Ingénieurs',
    'Ecole Supérieure de Technologie',
    'Institut d\'Études Islamiques',
    'Faculté de Médecine',
    'Faculté de Droit',
    'Faculté des Sciences Juridiques, Économiques et Sociales',
    'École Supérieure d\'Ingénieries',
  ];

  @override
  void dispose() {
    nomCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    bioCtrl.dispose();
    super.dispose();
  }

  Future<void> pickAvatar() async {
    final f = await picker.pickImage(source: ImageSource.gallery);
    if (f != null) {
      setState(() => avatarFile = f);
    }
  }

  Future<void> submit() async {
    // Validation
    if (emailCtrl.text.isEmpty || passCtrl.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email et mot de passe requis')),
      );
      return;
    }

    if (!isLogin) {
      if (nomCtrl.text.isEmpty || selectedFaculty == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tous les champs sont requis')),
        );
        return;
      }
    }

    setState(() => isLoading = true);

    try {
      if (isLogin) {
        // LOGIN
        final res = await http
            .post(
              Uri.parse('$API_URL/login'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'email': emailCtrl.text,
                'password': passCtrl.text,
              }),
            )
            .timeout(const Duration(seconds: 10));

        if (!mounted) return;
        setState(() => isLoading = false);

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', data['token']);
          await prefs.setString('userId', data['user']['id']);

          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => FeedScreen(token: data['token'])),
          );
        } else {
          try {
            final error = jsonDecode(res.body);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur: ${error['message']}')),
            );
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Erreur ${res.statusCode}')));
          }
        }
      } else {
        // REGISTER with multipart
        final req = http.MultipartRequest(
          'POST',
          Uri.parse('$API_URL/register'),
        );

        req.fields['nom'] = nomCtrl.text;
        req.fields['email'] = emailCtrl.text;
        req.fields['password'] = passCtrl.text;
        req.fields['faculty'] = selectedFaculty!;
        req.fields['bio'] = bioCtrl.text;

        if (avatarFile != null) {
          try {
            req.files.add(
              await http.MultipartFile.fromPath('avatar', avatarFile!.path),
            );
          } catch (e) {
            debugPrint('Avatar upload error: $e');
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Erreur upload avatar')),
            );
            setState(() => isLoading = false);
            return;
          }
        }

        final streamedResponse = await req.send().timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception('Timeout - serveur non accessible');
          },
        );

        final res = await http.Response.fromStream(streamedResponse);

        if (!mounted) return;
        setState(() => isLoading = false);

        if (res.statusCode == 201) {
          final data = jsonDecode(res.body);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', data['token']);
          await prefs.setString('userId', data['user']['id']);

          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Inscription réussie!')));

          if (!mounted) return;
          // Navigate to verification screen; backend returns a verificationCode for testing
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => VerifyEmailScreen(
                email: emailCtrl.text,
                serverCode: data['verificationCode'],
              ),
            ),
          );
        } else {
          try {
            final error = jsonDecode(res.body);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur: ${error['message']}')),
            );
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur ${res.statusCode}: ${res.body}')),
            );
          }
        }
      }
    } on http.ClientException catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      debugPrint('ClientException: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur connexion: Vérifiez que le serveur tourne sur $API_URL',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      debugPrint('Error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isLogin ? 'Connexion' : 'Inscription')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!isLogin) ...[
                // Avatar picker
                Center(
                  child: GestureDetector(
                    onTap: pickAvatar,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: avatarFile != null
                              ? FileImage(File(avatarFile!.path))
                              : null,
                          child: avatarFile == null
                              ? Icon(
                                  Icons.camera_alt,
                                  size: 40,
                                  color: Colors.grey[700],
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFF003366),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Nom
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: nomCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nom complet',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                ),
                // Faculty
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DropdownButtonFormField<String>(
                    initialValue: selectedFaculty,
                    items: faculties
                        .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                        .toList(),
                    onChanged: (v) => setState(() => selectedFaculty = v),
                    decoration: const InputDecoration(
                      labelText: 'Faculté / École / Institut',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.school),
                    ),
                  ),
                ),
                // Bio
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: bioCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Bio (optionnel)',
                      hintText: 'Écrivez quelque chose sur vous...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.info),
                    ),
                  ),
                ),
              ],
              // Email
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email @usmba.ac.ma',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
              ),
              // Password
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: TextField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mot de passe',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
              ),
              // Submit Button
              ElevatedButton(
                onPressed: isLoading ? null : submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: const Color(0xFF003366),
                  disabledBackgroundColor: Colors.grey,
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(
                        isLogin ? 'Se connecter' : 'S\'inscrire',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              // Toggle Login/Register
              TextButton(
                onPressed: () {
                  setState(() => isLogin = !isLogin);
                  nomCtrl.clear();
                  emailCtrl.clear();
                  passCtrl.clear();
                  bioCtrl.clear();
                  selectedFaculty = null;
                  avatarFile = null;
                },
                child: Text(
                  isLogin ? 'Créer un compte' : 'Déjà inscrit ?',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF003366),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
