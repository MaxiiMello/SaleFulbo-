import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../services/storage_service.dart';
import '../state/auth_controller.dart';
import '../widgets/photo_picker.dart';

/// Página para que los usuarios configuren su perfil
class ProfileSetupPage extends ConsumerStatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  ConsumerState<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends ConsumerState<ProfileSetupPage> {
  late TextEditingController _nicknameController;
  File? _selectedPhoto;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final AppUser? user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario no autenticado')),
      );
      return;
    }

    final String nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa un apodo')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? photoUrl = user.photoUrl;

      // Si hay una foto nuevamente seleccionada, uploadearla
      if (_selectedPhoto != null) {
        final StorageService storage = StorageService();
        photoUrl = await storage.uploadProfilePhoto(
          userId: user.id,
          imageFile: _selectedPhoto!,
        );
      }

      // Actualizar perfil del usuario
      final AppUser updatedUser = user.copyWith(
        nickname: nickname,
        photoUrl: photoUrl,
      );

      // TODO: Guardar cambios en Firestore
      // await ref.read(authControllerProvider.notifier).updateProfile(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Perfil actualizado exitosamente')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar Perfil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            // Photo Picker
            PhotoPicker(
              onPhotoSelected: (File photo) {
                setState(() {
                  _selectedPhoto = photo;
                });
              },
              label: 'Cambiar foto de perfil',
            ),
            const SizedBox(height: 32),

            // Nickname input
            TextField(
              controller: _nicknameController,
              decoration: InputDecoration(
                labelText: 'Apodo',
                hintText: 'Ej: "Messi", "Pelé"',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isLoading ? null : _saveProfile,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_isLoading ? 'Guardando...' : 'Guardar Perfil'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
