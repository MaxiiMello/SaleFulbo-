import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../navigation/app_routes.dart';
import '../state/auth_controller.dart';

class RegisterPage extends ConsumerWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AppUser?> authState = ref.watch(authControllerProvider);
    final bool firebaseConfigured = ref.watch(authServiceProvider).firebaseConfigured;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.sports_soccer, size: 72),
              const SizedBox(height: 12),
              const Text(
                'SaleFulbo',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Crea tu cuenta para publicar y unirte a partidos.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () async {
                  try {
                    await ref.read(authControllerProvider.notifier).signInWithGoogle();
                    if (!context.mounted) return;
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.home,
                      (_) => false,
                    );
                  } catch (error) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error de registro: $error')),
                    );
                  }
                },
                icon: const Icon(Icons.person_add),
                label: const Text('Registrarse con Google'),
              ),
              if (!firebaseConfigured) ...<Widget>[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(authControllerProvider.notifier).signInDemo();
                    if (!context.mounted) return;
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.home,
                      (_) => false,
                    );
                  },
                  icon: const Icon(Icons.smartphone),
                  label: const Text('Entrar en modo demo'),
                ),
              ],
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed(AppRoutes.login);
                },
                child: const Text('¿Ya tienes cuenta? Inicia sesión'),
              ),
              const SizedBox(height: 12),
              authState.when(
                data: (_) => const SizedBox.shrink(),
                loading: () => const CircularProgressIndicator(),
                error: (Object error, StackTrace _) => Text(
                  'Estado auth: $error',
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Seguridad: Google + ID único de usuario. Para blindar cuentas duplicadas al 100%, se recomienda validar teléfono o documento en backend.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
