import 'package:flutter/material.dart';

import '../models/match_post.dart';
import 'rating_badge.dart';

class MatchCard extends StatelessWidget {
  const MatchCard({
    required this.match,
    required this.currentUserId,
    required this.onJoin,
    required this.onOpenMap,
    required this.onCreatorPlus,
    required this.onCreatorMinus,
    required this.onCloseMatch,
    super.key,
  });

  final MatchPost match;
  final String currentUserId;
  final VoidCallback onJoin;
  final VoidCallback onOpenMap;
  final VoidCallback onCreatorPlus;
  final VoidCallback onCreatorMinus;
  final VoidCallback onCloseMatch;

  String _formatSchedule(DateTime value) {
    final String dd = value.day.toString().padLeft(2, '0');
    final String mm = value.month.toString().padLeft(2, '0');
    final String yyyy = value.year.toString();
    final String hh = value.hour.toString().padLeft(2, '0');
    final String min = value.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy - $hh:$min';
  }

  @override
  Widget build(BuildContext context) {
    final bool isCreator = currentUserId == match.createdByUserId;
    final bool joined = match.joinedPlayerIds.contains(currentUserId);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              match.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text('Cancha: ${match.courtName}'),
            Text('Creador: ${match.createdByName}'),
            Text('Faltan: ${match.missingPlayers} de ${match.totalPlayers}'),
            Text('Categoria: ${footballFormatLabel(match.format)}'),
            Text('Intensidad: ${intensityLabel(match.intensity)}'),
            Text('Precio por jugador: ${match.pricePerPlayer.toStringAsFixed(0)}'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                ActionChip(
                  avatar: const Icon(Icons.location_on_outlined, size: 18),
                  onPressed: onOpenMap,
                  label: const Text('Ver ubicacion'),
                ),
                FilledButton.icon(
                  onPressed: joined || isCreator || match.isClosed ? null : onJoin,
                  icon: Icon(
                    joined
                        ? Icons.check
                        : isCreator || match.isClosed
                            ? Icons.lock_outline
                            : Icons.person_add_alt_1,
                  ),
                  label: Text(
                    joined
                        ? 'Presencia confirmada'
                        : isCreator
                            ? 'Eres el creador'
                            : match.isClosed
                                ? 'Partido cerrado'
                                : 'Unirme como jugador',
                  ),
                ),
              ],
            ),
            if (isCreator) ...<Widget>[
              const Divider(height: 22),
              const Text(
                'Herramientas del creador',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: match.isClosed ? null : onCreatorMinus,
                    icon: const Icon(Icons.remove),
                    label: const Text('Bajar faltantes'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: match.isClosed ? null : onCreatorPlus,
                    icon: const Icon(Icons.add),
                    label: const Text('Subir faltantes'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: match.isClosed ? null : onCloseMatch,
                icon: const Icon(Icons.cancel_outlined),
                label: Text(match.isClosed ? 'Partido cerrado' : 'Cerrar futbol'),
              ),
            ],
            const SizedBox(height: 10),
            Text('Horario: ${_formatSchedule(match.scheduledAt)}'),
            if (match.isClosed)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Estado: Cerrado por el creador',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                RatingBadge(
                  label: 'Creador',
                  rating: match.creatorRating,
                  icon: Icons.verified_user,
                ),
                const SizedBox(width: 8),
                RatingBadge(
                  label: 'Jugador',
                  rating: match.playerRating,
                  icon: Icons.sports,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
