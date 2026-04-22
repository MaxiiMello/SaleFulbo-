import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Widget para seleccionar y mostrar preview de foto
class PhotoPicker extends StatefulWidget {
  const PhotoPicker({
    required this.onPhotoSelected,
    this.initialPhotoUrl,
    this.label = 'Seleccionar foto',
    super.key,
  });

  final Function(File) onPhotoSelected;
  final String? initialPhotoUrl;
  final String label;

  @override
  State<PhotoPicker> createState() => _PhotoPickerState();
}

class _PhotoPickerState extends State<PhotoPicker> {
  File? _selectedFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // Compress a 70%
        maxWidth: 800,
        maxHeight: 800,
      );

      if (pickedFile != null) {
        final File file = File(pickedFile.path);
        setState(() {
          _selectedFile = file;
        });
        widget.onPhotoSelected(file);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar foto: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasPhoto = _selectedFile != null || widget.initialPhotoUrl != null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        if (hasPhoto)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _selectedFile != null
                ? Image.file(
                    _selectedFile!,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  )
                : Image.network(
                    widget.initialPhotoUrl!,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.image_not_supported),
                      );
                    },
                  ),
          )
        else
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.image, size: 48, color: Colors.grey),
          ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.add_photo_alternate),
          label: Text(widget.label),
        ),
      ],
    );
  }
}
