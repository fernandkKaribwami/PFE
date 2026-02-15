import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/post_service.dart';

class CreatePostScreen extends StatefulWidget {
  final VoidCallback? onPostCreated;
  const CreatePostScreen({super.key, this.onPostCreated});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final PostService _postService = PostService();
  final textCtrl = TextEditingController();
  final picker = ImagePicker();

  XFile? media;
  bool isPublic = true;
  bool sending = false;

  @override
  void dispose() {
    textCtrl.dispose();
    super.dispose();
  }

  Future<void> pickMedia(ImageSource src) async {
    final f = await picker.pickImage(source: src);
    if (f != null) {
      setState(() => media = f);
    }
  }

  Future<void> pickVideo(ImageSource src) async {
    final f = await picker.pickVideo(source: src);
    if (f != null) {
      setState(() => media = f);
    }
  }

  Future<void> send() async {
    if (textCtrl.text.isEmpty && media == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Écrivez quelque chose ou ajoutez un fichier'),
        ),
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
