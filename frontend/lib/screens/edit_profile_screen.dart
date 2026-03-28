import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../services/faculty_service.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../utils/app_config.dart';
import '../widgets/loading_button.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const List<String> _levels = [
    'L1',
    'L2',
    'L3',
    'M1',
    'M2',
    'Doctorat',
  ];

  final UserService _userService = UserService();
  final FacultyService _facultyService = FacultyService();
  final ImagePicker _imagePicker = ImagePicker();

  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  late final TextEditingController _interestsController;
  late final TextEditingController _avatarUrlController;
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  List<dynamic> _faculties = [];
  String? _selectedFacultyId;
  String _selectedLevel = 'L1';
  XFile? _selectedAvatar;
  Uint8List? _selectedAvatarBytes;
  bool _removeAvatar = false;
  bool _isSaving = false;
  bool _isLoadingFaculties = false;

  @override
  void initState() {
    super.initState();
    final interests =
        (widget.user['interests'] as List? ?? const [])
            .map((item) => item.toString())
            .join(', ');

    _nameController = TextEditingController(
      text: widget.user['name']?.toString() ?? '',
    );
    _bioController = TextEditingController(
      text: widget.user['bio']?.toString() ?? '',
    );
    _interestsController = TextEditingController(text: interests);
    _avatarUrlController = TextEditingController(
      text: widget.user['avatar']?.toString() ?? '',
    );
    _selectedFacultyId = widget.user['faculty']?['_id']?.toString();
    _selectedLevel = widget.user['level']?.toString() ?? 'L1';

    _loadFaculties();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _interestsController.dispose();
    _avatarUrlController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadFaculties() async {
    setState(() {
      _isLoadingFaculties = true;
    });

    try {
      final faculties = await _facultyService.getFaculties();
      if (!mounted) {
        return;
      }

      setState(() {
        _faculties = faculties;
        _isLoadingFaculties = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingFaculties = false;
      });
    }
  }

  Future<void> _pickAvatar() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image == null) {
      return;
    }

    final bytes = await image.readAsBytes();
    if (!mounted) {
      return;
    }

    setState(() {
      _selectedAvatar = image;
      _selectedAvatarBytes = bytes;
      _removeAvatar = false;
      _avatarUrlController.clear();
    });
  }

  ImageProvider<Object>? _avatarPreview() {
    if (_selectedAvatarBytes != null) {
      return MemoryImage(_selectedAvatarBytes!);
    }

    final resolved = AppConfig.resolveUrl(_avatarUrlController.text.trim());
    if (resolved.isNotEmpty) {
      return NetworkImage(resolved);
    }

    return null;
  }

  bool get _shouldUpdatePassword {
    return _currentPasswordController.text.trim().isNotEmpty ||
        _newPasswordController.text.trim().isNotEmpty ||
        _confirmPasswordController.text.trim().isNotEmpty;
  }

  Future<void> _saveProfile() async {
    final messenger = ScaffoldMessenger.of(context);
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Le nom est obligatoire')),
      );
      return;
    }

    if (_shouldUpdatePassword) {
      if (_currentPasswordController.text.trim().isEmpty ||
          _newPasswordController.text.trim().isEmpty ||
          _confirmPasswordController.text.trim().isEmpty) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Completez les 3 champs mot de passe'),
          ),
        );
        return;
      }

      if (_newPasswordController.text != _confirmPasswordController.text) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('La confirmation du mot de passe ne correspond pas'),
          ),
        );
        return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedUser = await _userService.updateProfile(
        name: name,
        bio: _bioController.text.trim(),
        facultyId: _selectedFacultyId,
        level: _selectedLevel,
        interests: _interestsController.text.trim(),
        avatarPath: _selectedAvatar?.path,
        avatarBytes: _selectedAvatarBytes,
        avatarFileName: _selectedAvatar?.name,
        avatarUrl: _removeAvatar
            ? ''
            : _avatarUrlController.text.trim().isEmpty
            ? null
            : _avatarUrlController.text.trim(),
      );

      if (updatedUser == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Mise a jour du profil impossible')),
        );
        return;
      }

      if (_shouldUpdatePassword) {
        final passwordError = await _userService.changePassword(
          currentPassword: _currentPasswordController.text.trim(),
          newPassword: _newPasswordController.text.trim(),
          confirmPassword: _confirmPasswordController.text.trim(),
        );

        if (passwordError != null) {
          messenger.showSnackBar(SnackBar(content: Text(passwordError)));
          return;
        }
      }

      if (!mounted) {
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      authProvider.mergeUser(updatedUser);

      final token = authProvider.token;
      if (token != null && token.isNotEmpty) {
        await userProvider.loadUserProfile(token);
      }

      if (!mounted) {
        return;
      }

      messenger.showSnackBar(
        const SnackBar(content: Text('Profil mis a jour avec succes')),
      );
      Navigator.pop(context, true);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarImage = _avatarPreview();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le profil'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      backgroundImage: avatarImage,
                      child: avatarImage == null
                          ? Text(
                              nameInitial(name: _nameController.text),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _isSaving ? null : _pickAvatar,
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Choisir une photo'),
                        ),
                        TextButton.icon(
                          onPressed: _isSaving
                              ? null
                              : () {
                              setState(() {
                                _selectedAvatar = null;
                                _selectedAvatarBytes = null;
                                _removeAvatar = true;
                                _avatarUrlController.clear();
                              });
                            },
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Retirer'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nom complet',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _bioController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _interestsController,
                decoration: const InputDecoration(
                  labelText: 'Centres d interet',
                  hintText: 'reseaux, flutter, data, IA',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _avatarUrlController,
                onChanged: (_) {
                  setState(() {
                    _removeAvatar = false;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'URL de la photo (optionnel)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _faculties.any(
                  (faculty) =>
                      (faculty as Map)['_id']?.toString() == _selectedFacultyId,
                )
                    ? _selectedFacultyId
                    : null,
                items: _faculties
                    .map<DropdownMenuItem<String>>((faculty) {
                      final item = Map<String, dynamic>.from(faculty as Map);
                      final id = item['_id']?.toString() ?? '';
                      return DropdownMenuItem<String>(
                        value: id,
                        child: Text(item['name']?.toString() ?? 'Faculte'),
                      );
                    })
                    .toList(),
                onChanged: _isLoadingFaculties
                    ? null
                    : (value) {
                        setState(() {
                          _selectedFacultyId = value;
                        });
                      },
                decoration: InputDecoration(
                  labelText: 'Faculte',
                  border: const OutlineInputBorder(),
                  suffixIcon: _isLoadingFaculties
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedLevel,
                items: _levels
                    .map(
                      (level) => DropdownMenuItem<String>(
                        value: level,
                        child: Text(level),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _selectedLevel = value;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Niveau',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Changer le mot de passe',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mot de passe actuel',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nouveau mot de passe',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmer le nouveau mot de passe',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              LoadingButton(
                onPressed: _saveProfile,
                isLoading: _isSaving,
                text: 'Enregistrer',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String nameInitial({required String name}) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    return 'U';
  }
  return trimmed.substring(0, 1).toUpperCase();
}
