import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/auth_provider.dart';
import '../services/faculty_service.dart';
import '../theme/app_colors.dart';
import '../widgets/loading_button.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _facultyController = TextEditingController();
  final _bioController = TextEditingController();

  // State
  bool _isLogin = true;
  String _selectedRole = 'student';
  XFile? _avatarFile;
  final ImagePicker _picker = ImagePicker();

  final FacultyService _facultyService = FacultyService();
  List<dynamic> _faculties = [];
  String? _selectedFacultyId;
  String? _facultiesError;
  bool _isLoadingFaculties = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _isLogin = _tabController.index == 0;
      });
    });
    _loadFaculties();
  }

  Future<void> _loadFaculties() async {
    setState(() {
      _isLoadingFaculties = true;
      _facultiesError = null;
    });

    try {
      final faculties = await _facultyService.getFaculties();
      if (mounted) {
        setState(() {
          _faculties = faculties;
          _isLoadingFaculties = false;
          if (_faculties.isEmpty) {
            _facultiesError =
                'Aucune faculté disponible. Vérifiez votre connexion.';
          } else if (_selectedFacultyId == null) {
            _selectedFacultyId = _faculties.first['_id']?.toString();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingFaculties = false;
          _facultiesError = 'Erreur lors du chargement des facultés: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _facultyController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _avatarFile = image;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (_isLogin) {
      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        Navigator.pushReplacementNamed(context, '/main');
      }
    } else {
      final success = await authProvider.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        faculty: _selectedFacultyId ?? '',
        role: _selectedRole,
        bio: _bioController.text.isNotEmpty ? _bioController.text : null,
        avatarPath: _avatarFile?.path,
      );

      if (success && mounted) {
        // Navigate to email verification or main screen
        Navigator.pushReplacementNamed(context, '/main');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.1),
              AppColors.primary.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),

                  // Logo and Title
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.school,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'USMBA Social',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Réseau social universitaire',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Tab Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey[600],
                      tabs: const [
                        Tab(text: 'Connexion'),
                        Tab(text: 'Inscription'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Tab Bar View
                  SizedBox(
                    height: _isLogin ? 300 : 500,
                    child: TabBarView(
                      controller: _tabController,
                      children: [_buildLoginForm(), _buildRegisterForm()],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Submit Button
                  LoadingButton(
                    onPressed: _submit,
                    isLoading: authProvider.isLoading,
                    text: _isLogin ? 'Se connecter' : 'S\'inscrire',
                  ),

                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () async {
                      final success = await authProvider.loginWithGoogle();
                      if (success && mounted) {
                        Navigator.pushReplacementNamed(context, '/main');
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      side: const BorderSide(color: Colors.grey),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.login, color: Colors.black87),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Se connecter avec Google',
                            softWrap: true,
                            style: const TextStyle(color: Colors.black87),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Error Message
                  if (authProvider.error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
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
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email @usmba.ac.ma',
            prefixIcon: Icon(Icons.email),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
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
            prefixIcon: Icon(Icons.lock),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Mot de passe requis';
            }
            if (value.length < 6) {
              return 'Minimum 6 caractères';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      children: [
        // Avatar Picker
        Center(
          child: GestureDetector(
            onTap: _pickAvatar,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _avatarFile != null
                      ? FileImage(File(_avatarFile!.path))
                      : null,
                  child: _avatarFile == null
                      ? Icon(
                          Icons.camera_alt,
                          size: 30,
                          color: Colors.grey[600],
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Nom complet',
            prefixIcon: Icon(Icons.person),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
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
            prefixIcon: Icon(Icons.email),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Email requis';
            }
            if (!value.contains('@')) {
              return 'Email invalide';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Faculty Loading Error Message
        if (_facultiesError != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _facultiesError!,
                    style: TextStyle(color: Colors.red[700], fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _isLoadingFaculties ? null : _loadFaculties,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isLoadingFaculties)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    const Icon(Icons.refresh),
                  const SizedBox(width: 8),
                  Text(_isLoadingFaculties ? 'Chargement...' : 'Réessayer'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        DropdownButtonFormField<String>(
          value: _selectedFacultyId,
          decoration: const InputDecoration(
            labelText: 'Faculté / École / Institut',
            prefixIcon: Icon(Icons.school),
          ),
          items: _faculties.isNotEmpty
              ? _faculties.map((faculty) {
                  final id = faculty['_id']?.toString();
                  final name =
                      faculty['name']?.toString() ?? 'Faculté inconnue';
                  return DropdownMenuItem(value: id, child: Text(name));
                }).toList()
              : [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Chargement des facultés...'),
                  ),
                ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedFacultyId = value;
                _facultyController.text = value;
              });
            }
          },
          validator: (value) {
            if (_facultiesError != null) {
              return 'Merci de recharger les facultés';
            }
            if (_faculties.isEmpty) {
              return 'Chargement des facultés en cours...';
            }
            if (value == null || value.isEmpty) {
              return 'Faculté requise';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        DropdownButtonFormField<String>(
          value: _selectedRole,
          decoration: const InputDecoration(
            labelText: 'Rôle',
            prefixIcon: Icon(Icons.person_outline),
          ),
          items: const [
            DropdownMenuItem(value: 'student', child: Text('Étudiant')),
            DropdownMenuItem(value: 'teacher', child: Text('Professeur')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedRole = value ?? 'student';
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Rôle requis';
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
            prefixIcon: Icon(Icons.lock),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Mot de passe requis';
            }
            if (value.length < 6) {
              return 'Minimum 6 caractères';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        TextFormField(
          controller: _bioController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Bio (optionnel)',
            hintText: 'Parlez-nous de vous...',
            prefixIcon: Icon(Icons.info),
          ),
        ),
      ],
    );
  }
}
