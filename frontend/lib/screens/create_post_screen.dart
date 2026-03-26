import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../providers/feed_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/loading_button.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  XFile? _selectedMedia;
  bool _isPublic = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _selectedMedia = image;
      });
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    final XFile? video = await _picker.pickVideo(source: source);
    if (video != null) {
      setState(() {
        _selectedMedia = video;
      });
    }
  }

  void _removeMedia() {
    setState(() {
      _selectedMedia = null;
    });
  }

  Future<void> _createPost() async {
    if (_textController.text.trim().isEmpty && _selectedMedia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoutez du texte ou un média')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Here you would typically call an API to create the post
      // For now, we'll simulate it and add to the feed
      final newPost = {
        '_id': DateTime.now().millisecondsSinceEpoch.toString(),
        'author': {
          'name': 'Current User', // This should come from auth provider
          'avatar': null,
        },
        'content': _textController.text.trim(),
        'media': _selectedMedia?.path,
        'mediaType': _selectedMedia != null
            ? (_selectedMedia!.path.endsWith('.mp4') ? 'video' : 'image')
            : null,
        'createdAt': DateTime.now().toIso8601String(),
        'likesCount': 0,
        'commentsCount': 0,
        'isLiked': false,
        'isPublic': _isPublic,
      };

      // Add to feed
      final feedProvider = Provider.of<FeedProvider>(context, listen: false);
      feedProvider.addNewPost(newPost);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Post créé avec succès!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un post'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createPost,
            child: Text(
              'Publier',
              style: TextStyle(
                color: _isLoading ? Colors.grey : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Text Input
            TextField(
              controller: _textController,
              maxLines: 8,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: 'Quoi de neuf à l\'USMBA ?',
                border: InputBorder.none,
                counterText: '',
              ),
              style: const TextStyle(fontSize: 16),
            ),

            // Media Preview
            if (_selectedMedia != null) ...[
              const SizedBox(height: 16),
              Stack(
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: FileImage(File(_selectedMedia!.path)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      onPressed: _removeMedia,
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Media Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo),
                    label: const Text('Photo'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Caméra'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            OutlinedButton.icon(
              onPressed: () => _pickVideo(ImageSource.gallery),
              icon: const Icon(Icons.video_file),
              label: const Text('Vidéo'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Privacy Toggle
            SwitchListTile(
              title: const Text('Post public'),
              subtitle: Text(
                _isPublic
                    ? 'Visible par tous les utilisateurs'
                    : 'Visible uniquement par vos abonnements',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              value: _isPublic,
              onChanged: (value) {
                setState(() => _isPublic = value);
              },
            ),

            const SizedBox(height: 24),

            // Create Button
            LoadingButton(
              onPressed: _createPost,
              isLoading: _isLoading,
              text: 'Publier',
            ),
          ],
        ),
      ),
    );
  }
}
