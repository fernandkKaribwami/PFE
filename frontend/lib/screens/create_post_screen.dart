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
        'mediaType': _selectedMedia != null ? (_selectedMedia!.path.endsWith('.mp4') ? 'video' : 'image') : null,
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post créé avec succès!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
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
      );
      return;
    }

    setState(() => sending = true);

    try {
      final success = await _postService.createPost(
        text: textCtrl.text,
        isPublic: isPublic,
        filePath: media?.path,
      );

      if (!mounted) return;
      setState(() => sending = false);

      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Post publié! 🎉')));
        widget.onPostCreated?.call();
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la publication')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => sending = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un post'),
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
        actions: [
          if (!sending)
            TextButton(
              onPressed: send,
              child: const Text(
                'Publier',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
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
            TextField(
              controller: textCtrl,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Quoi de neuf?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 16),
            if (media != null)
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[200],
                    ),
                    child: kIsWeb
                        ? Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: Text('Fichier sélectionné'),
                            ),
                          )
                        : Image.file(File(media!.path), fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => media = null),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MediaButton(
                  icon: Icons.image,
                  label: 'Image',
                  onPressed: () => pickMedia(ImageSource.gallery),
                ),
                _MediaButton(
                  icon: Icons.video_library,
                  label: 'Vidéo',
                  onPressed: () => pickVideo(ImageSource.gallery),
                ),
                _MediaButton(
                  icon: Icons.public,
                  label: isPublic ? 'Public' : 'Privé',
                  onPressed: () => setState(() => isPublic = !isPublic),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '💡 Conseil',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Utilisez #hashtags pour catégoriser votre post'),
                  const Text(
                    'Utilisez @mentions pour notifier d\'autres utilisateurs',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _MediaButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, color: const Color(0xFF003366), size: 28),
          onPressed: onPressed,
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
