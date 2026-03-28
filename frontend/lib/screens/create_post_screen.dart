import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/feed_provider.dart';
import '../services/post_service.dart';
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
  final PostService _postService = PostService();

  XFile? _selectedMedia;
  Uint8List? _selectedMediaBytes;
  bool _isVideoSelected = false;
  bool _isPublic = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final image = await _picker.pickImage(source: source);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedMedia = image;
        _selectedMediaBytes = bytes;
        _isVideoSelected = false;
      });
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    final video = await _picker.pickVideo(source: source);
    if (video != null) {
      setState(() {
        _selectedMedia = video;
        _selectedMediaBytes = null;
        _isVideoSelected = true;
      });
    }
  }

  void _removeMedia() {
    setState(() {
      _selectedMedia = null;
      _selectedMediaBytes = null;
      _isVideoSelected = false;
    });
  }

  Future<void> _createPost() async {
    if (_textController.text.trim().isEmpty && _selectedMedia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoutez du texte ou un media')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final feedProvider = Provider.of<FeedProvider>(context, listen: false);

      final createdPost = await _postService.createPost(
        text: _textController.text.trim(),
        isPublic: _isPublic,
        filePath: _selectedMedia?.path,
        fileBytes: _selectedMediaBytes,
        fileName: _selectedMedia?.name,
        faculty: authProvider.user?['faculty']?['_id']?.toString(),
      );

      if (createdPost == null) {
        throw Exception('Creation du post impossible');
      }

      await feedProvider.addNewPost(createdPost);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post cree avec succes!')),
        );
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
        title: const Text('Creer un post'),
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
            TextField(
              controller: _textController,
              maxLines: 8,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: 'Quoi de neuf a l USMBA ?',
                border: InputBorder.none,
                counterText: '',
              ),
              style: const TextStyle(fontSize: 16),
            ),
            if (_selectedMedia != null) ...[
              const SizedBox(height: 16),
              Stack(
                children: [
                  _buildMediaPreview(),
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
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo),
                    label: const Text('Photo'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _pickVideo(ImageSource.gallery),
              icon: const Icon(Icons.video_file),
              label: const Text('Video'),
            ),
            const SizedBox(height: 24),
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

  Widget _buildMediaPreview() {
    if (_selectedMedia == null) {
      return const SizedBox.shrink();
    }

    if (_isVideoSelected) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.black12,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.video_file, size: 48, color: Colors.black54),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _selectedMedia!.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    if (_selectedMediaBytes != null) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          image: DecorationImage(
            image: MemoryImage(_selectedMediaBytes!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black12,
      ),
      child: Center(
        child: Text(
          kIsWeb ? 'Apercu indisponible' : _selectedMedia!.name,
        ),
      ),
    );
  }
}
