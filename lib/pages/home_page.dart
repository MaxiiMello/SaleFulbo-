import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_user.dart';
import '../navigation/app_routes.dart';
import '../models/match_post.dart';
import '../services/reminder_service.dart';
import '../state/auth_controller.dart';
import '../state/matches_controller.dart';
import '../widgets/empty_state.dart';
import '../widgets/match_card.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late final ReminderService _reminderService;

  @override
  void initState() {
    super.initState();
    _reminderService = ReminderService(onReminder: _showReminderMessage);
  }

  @override
  void dispose() {
    _reminderService.dispose();
    super.dispose();
  }

  void _showReminderMessage(MatchPost match) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Recordatorio: tienes futbol en ${match.courtName}. Confirmaste presencia.',
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _openCreateMatchForm() async {
    final AppUser? currentUser = ref.read(authControllerProvider).valueOrNull;
    if (currentUser == null) {
      _showSimpleMessage('Necesitas iniciar sesion.');
      return;
    }

    final MatchPost? match = await Navigator.of(context).pushNamed<MatchPost>(
      AppRoutes.createMatch,
      arguments: currentUser,
    );

    if (match == null) return;
    await ref.read(matchesControllerProvider).addMatch(match);
  }

  void _adjustMissingPlayers(MatchPost match, int delta) {
    ref.read(matchesControllerProvider).adjustMissingPlayers(match.id, delta);
  }

  Future<void> _joinAsPlayer(MatchPost match) async {
    final AppUser? currentUser = ref.read(authControllerProvider).valueOrNull;
    if (currentUser == null) {
      _showSimpleMessage('Necesitas iniciar sesion.');
      return;
    }

    final JoinMatchResult result =
        await ref.read(matchesControllerProvider).joinAsPlayer(match.id, currentUser.id);

    if (!mounted) return;

    switch (result.status) {
      case JoinMatchStatus.full:
        _showSimpleMessage('Ese partido ya esta completo.');
        return;
      case JoinMatchStatus.closed:
        _showSimpleMessage('Este partido ya fue cerrado por el creador.');
        return;
      case JoinMatchStatus.alreadyJoined:
        _showSimpleMessage('Ya confirmaste tu presencia en este partido.');
        return;
      case JoinMatchStatus.creatorCannotJoin:
        _showSimpleMessage('El creador no puede unirse a su propio partido.');
        return;
      case JoinMatchStatus.notFound:
        _showSimpleMessage('No encontramos ese partido.');
        return;
      case JoinMatchStatus.joined:
        if (result.match != null) {
          _reminderService.startReminder(result.match!);
        }
        _showSimpleMessage('Te uniste. Te avisaremos cada 20 minutos.');
        return;
    }
  }

  Future<void> _closeMatch(MatchPost match) async {
    final AppUser? currentUser = ref.read(authControllerProvider).valueOrNull;
    if (currentUser == null) {
      _showSimpleMessage('Necesitas iniciar sesion.');
      return;
    }

    final bool shouldClose = await _confirmCloseMatchDialog(match);
    if (!shouldClose) return;

    final CloseMatchResult result =
        await ref.read(matchesControllerProvider).closeMatch(match.id, currentUser.id);

    if (!mounted) return;
    switch (result.status) {
      case CloseMatchStatus.closed:
        _showSimpleMessage('Partido cerrado y removido del listado.');
        return;
      case CloseMatchStatus.notAuthorized:
        _showSimpleMessage('Solo el creador puede cerrar este partido.');
        return;
      case CloseMatchStatus.notFound:
        _showSimpleMessage('No encontramos ese partido.');
        return;
      case CloseMatchStatus.alreadyClosed:
        _showSimpleMessage('Ese partido ya estaba cerrado.');
        return;
    }
  }

  Future<bool> _confirmCloseMatchDialog(MatchPost match) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar partido'),
          content: Text('Deseas cerrar "${match.title}"? Esta accion lo quitara del listado.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Si, cerrar'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  void _showSimpleMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openCourtMap(MatchPost match) async {
    final Uri mapsUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${match.latitude},${match.longitude}',
    );
    if (!await launchUrl(mapsUri, mode: LaunchMode.externalApplication)) {
      _showSimpleMessage('No se pudo abrir el mapa.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppUser? currentUser = ref.watch(authControllerProvider).valueOrNull;
    final AsyncValue<List<MatchPost>> matchesAsync = ref.watch(matchesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SaleFulbo'),
        actions: <Widget>[
          IconButton(
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (!context.mounted) return;
              Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesion',
          ),
          IconButton(
            onPressed: _openCreateMatchForm,
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Crear partido',
          ),
        ],
      ),
      body: matchesAsync.when(
        data: (List<MatchPost> matches) {
          return matches.isEmpty
              ? const EmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: matches.length,
                  itemBuilder: (BuildContext context, int index) {
                    final MatchPost match = matches[index];
                    return MatchCard(
                      match: match,
                      currentUserId: currentUser?.id ?? '',
                      onOpenMap: () => _openCourtMap(match),
                      onJoin: () {
                        _joinAsPlayer(match);
                      },
                      onCreatorPlus: () {
                        _adjustMissingPlayers(match, 1);
                      },
                      onCreatorMinus: () {
                        _adjustMissingPlayers(match, -1);
                      },
                      onCloseMatch: () {
                        _closeMatch(match);
                      },
                    );
                  },
                );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stackTrace) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                const Text('Error al cargar los partidos'),
                const SizedBox(height: 8),
                Text('$error', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateMatchForm,
        icon: const Icon(Icons.sports_soccer),
        label: const Text('Publicar partido'),
      ),
    );
  }
}
