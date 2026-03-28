import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../utils/app_config.dart';
import '../widgets/loading_button.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  late final TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _bioController = TextEditingController();

  bool _isLogin = true;
  String _selectedRole = 'student';
  String? _selectedFaculty;
  XFile? _avatarFile;
  Uint8List? _avatarBytes;
  final ImagePicker _picker = ImagePicker();

  List<dynamic> _faculties = [];
  bool _isLoadingFaculties = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        return;
      }

      setState(() {
        _isLogin = _tabController.index == 0;
      });
      Provider.of<AuthProvider>(context, listen: false).clearError();

      if (!_isLogin && _faculties.isEmpty) {
        _loadFaculties();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadFaculties() async {
    if (_isLoadingFaculties) {
      return;
    }

    setState(() {
      _isLoadingFaculties = true;
    });

    try {
      final response = await http
          .get(Uri.parse('${AppConfig.apiBaseUrl}/faculties'))
          .timeout(const Duration(seconds: 10));

      if (!mounted) {
        return;
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _faculties = data is List ? data : [];
          _isLoadingFaculties = false;
        });
        return;
      }
    } catch (_) {
      // Keep a silent fallback here; the form remains usable.
    }

    if (mounted) {
      setState(() {
        _isLoadingFaculties = false;
      });
    }
  }

  Future<void> _pickAvatar() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) {
      return;
    }

    final bytes = await image.readAsBytes();
    if (!mounted) {
      return;
    }

    setState(() {
      _avatarFile = image;
      _avatarBytes = bytes;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (_isLogin) {
      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        Navigator.pushReplacementNamed(context, '/main');
      }
      return;
    }

    final success = await authProvider.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      faculty: _selectedFaculty ?? '',
      role: _selectedRole,
      bio: _bioController.text.trim().isNotEmpty
          ? _bioController.text.trim()
          : null,
      avatarPath: _avatarFile?.path,
    );

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/main');
    }
  }

  Future<void> _submitGoogleLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.loginWithGoogle();
    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/main');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withValues(alpha: 0.12),
              AppColors.primary.withValues(alpha: 0.06),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Card(
                  elevation: 8,
                  shadowColor: Colors.black.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 8),
                          _buildBranding(theme),
                          const SizedBox(height: 28),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: TabBar(
                              controller: _tabController,
                              indicator: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              labelColor: Colors.white,
                              unselectedLabelColor: Colors.grey[700],
                              tabs: const [
                                Tab(text: 'Connexion'),
                                Tab(text: 'Inscription'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            child: _isLogin
                                ? _buildLoginForm()
                                : _buildRegisterForm(),
                          ),
                          const SizedBox(height: 24),
                          LoadingButton(
                            onPressed: _submit,
                            isLoading: authProvider.isLoading,
                            text: _isLogin ? 'Se connecter' : 'S inscrire',
                            height: 54,
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed:
                                authProvider.isLoading ? null : _submitGoogleLogin,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black87,
                              side: const BorderSide(color: Colors.grey),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.login, color: Colors.black87),
                            label: const Text(
                              'Se connecter avec Google',
                              style: TextStyle(color: Colors.black87),
                            ),
                          ),
                          if (kIsWeb && AppConfig.googleClientId.isEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Pour tester Google sur le Web, lance Flutter avec --dart-define=GOOGLE_CLIENT_ID=...',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                          if (authProvider.error != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red[200]!),
                              ),
                              child: Text(
                                authProvider.error!,
                                style: TextStyle(color: Colors.red[700]),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBranding(ThemeData theme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(Icons.school, size: 44, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text(
          'USMBA Social',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Reseau social universitaire web, mobile et temps reel.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey[700],
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email @usmba.ac.ma',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Email requis';
            }
            if (!value.contains('@')) {
              return 'Email invalide';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Mot de passe',
            prefixIcon: Icon(Icons.lock_outline),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Mot de passe requis';
            }
            if (value.length < 6) {
              return 'Minimum 6 caracteres';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: GestureDetector(
            onTap: _pickAvatar,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.grey[200],
                  backgroundImage:
                      _avatarBytes != null ? MemoryImage(_avatarBytes!) : null,
                  child: _avatarFile == null
                      ? Icon(
                          Icons.camera_alt_outlined,
                          size: 28,
                          color: Colors.grey[600],
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Nom complet',
            prefixIcon: Icon(Icons.person_outline),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Nom requis';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email @usmba.ac.ma',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Email requis';
            }
            if (!value.contains('@')) {
              return 'Email invalide';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _isLoadingFaculties
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              )
            : DropdownButtonFormField<String>(
                key: ValueKey('faculty-${_selectedFaculty ?? ''}'),
                initialValue: _selectedFaculty,
                decoration: const InputDecoration(
                  labelText: 'Faculte / Ecole / Institut',
                  prefixIcon: Icon(Icons.school_outlined),
                ),
                hint: const Text('Selectionnez votre etablissement'),
                items: _faculties
                    .map<DropdownMenuItem<String>>((faculty) {
                      final id = faculty['_id']?.toString() ?? '';
                      final name =
                          faculty['name']?.toString() ?? 'Faculte inconnue';
                      return DropdownMenuItem<String>(
                        value: id,
                        child: Text(name),
                      );
                    })
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedFaculty = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La faculte est requise';
                  }
                  return null;
                },
              ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          key: ValueKey('role-$_selectedRole'),
          initialValue: _selectedRole,
          decoration: const InputDecoration(
            labelText: 'Role',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
          items: const [
            DropdownMenuItem(value: 'student', child: Text('Etudiant')),
            DropdownMenuItem(value: 'teacher', child: Text('Professeur')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedRole = value ?? 'student';
            });
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Mot de passe',
            prefixIcon: Icon(Icons.lock_outline),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Mot de passe requis';
            }
            if (value.length < 6) {
              return 'Minimum 6 caracteres';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _bioController,
          maxLines: 3,
          maxLength: 220,
          decoration: const InputDecoration(
            labelText: 'Bio',
            hintText: 'Presentez-vous en quelques lignes',
            prefixIcon: Icon(Icons.info_outline),
          ),
        ),
      ],
    );
  }
}
