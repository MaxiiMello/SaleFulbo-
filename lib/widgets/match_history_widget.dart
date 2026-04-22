import 'package:flutter/material.dart';

import '../models/match_post.dart';
import 'empty_state.dart';
import 'match_card.dart';

/// Widget para mostrar historial de partidos en Format TabBar
class MatchHistoryWidget extends StatefulWidget {
  const MatchHistoryWidget({
    required this.playedMatches,
    required this.organizedMatches,
    required this.currentUserId,
    super.key,
  });

  final List<MatchPost> playedMatches;
  final List<MatchPost> organizedMatches;
  final String currentUserId;

  @override
  State<MatchHistoryWidget> createState() => _MatchHistoryWidgetState();
}

class _MatchHistoryWidgetState extends State<MatchHistoryWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        TabBar(
          controller: _tabController,
          tabs: <Widget>[
            Tab(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(Icons.sports_soccer),
                  const SizedBox(height: 4),
                  Text('Jugados (${widget.playedMatches.length})'),
                ],
              ),
            ),
            Tab(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(Icons.edit),
                  const SizedBox(height: 4),
                  Text('Organizados (${widget.organizedMatches.length})'),
                ],
              ),
            ),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: <Widget>[
              // Tab: Jugados
              widget.playedMatches.isEmpty
                  ? const EmptyState(
                      icon: Icons.history,
                      title: 'Sin historial de partidos jugados',
                      subtitle: 'Cuando juegues partidos, aparecerán aquí',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: widget.playedMatches.length,
                      itemBuilder: (BuildContext context, int index) {
                        final MatchPost match = widget.playedMatches[index];
                        return _MatchHistoryCard(match: match);
                      },
                    ),

              // Tab: Organizados
              widget.organizedMatches.isEmpty
                  ? const EmptyState(
                      icon: Icons.emoji_events,
                      title: 'Sin partidos organizados',
                      subtitle: 'Cuando organices partidos, aparecerán aquí',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: widget.organizedMatches.length,
                      itemBuilder: (BuildContext context, int index) {
                        final MatchPost match = widget.organizedMatches[index];
                        return _MatchHistoryCard(match: match);
                      },
                    ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Tarjeta simplificada para historial (sin botones de acción)
class _MatchHistoryCard extends StatelessWidget {
  const _MatchHistoryCard({required this.match});

  final MatchPost match;

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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        match.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Creador: ${match.createdByName}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                if (match.isClosed)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Cerrado',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Finalizado',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: <Widget>[
                Text(
                  'Cancha: ${match.courtName}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'Fecha: ${_formatSchedule(match.scheduledAt)}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'Jugadores: ${match.totalPlayers - match.missingPlayers}/${match.totalPlayers}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  footballFormatLabel(match.format),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            if (match.joinedPlayerIds.isNotEmpty) ...<Widget>[
              const Divider(height: 16),
              Text(
                'Jugadores (${match.joinedPlayerIds.length}):',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: match.joinedPlayerIds
                    .map(
                      (String playerId) => Chip(
                        label: Text(
                          playerId.substring(0, (playerId.length ~/ 2).clamp(0, 8)),
                          style: const TextStyle(fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        side: BorderSide.none,
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
