import 'package:flutter/material.dart';

import '../models/match_post.dart';
import '../services/firestore_service.dart';
import '../widgets/match_history_widget.dart';

/// Página para ver historial completo de partidos
class MatchHistoryPage extends StatefulWidget {
  const MatchHistoryPage({
    required this.userId,
    required this.userName,
    super.key,
  });

  final String userId;
  final String userName;

  @override
  State<MatchHistoryPage> createState() => _MatchHistoryPageState();
}

class _MatchHistoryPageState extends State<MatchHistoryPage> {
  late Future<(List<MatchPost>, List<MatchPost>)> _historyFuture;
  final FirestoreService _firestore = FirestoreService();

  @override
  void initState() {
    super.initState();
    _historyFuture = _loadHistory();
  }

  Future<(List<MatchPost>, List<MatchPost>)> _loadHistory() async {
    final List<MatchPost> played = 
        await _firestore.getUserPlayedMatches(widget.userId);
    final List<MatchPost> organized = 
        await _firestore.getUserOrganizedMatches(widget.userId);
    return (played, organized);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historial - ${widget.userName}'),
      ),
      body: FutureBuilder<(List<MatchPost>, List<MatchPost>)>(
        future: _historyFuture,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  const Text('Error al cargar historial'),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('Sin datos'));
          }

          final (List<MatchPost> played, List<MatchPost> organized) = snapshot.data;

          return MatchHistoryWidget(
            playedMatches: played,
            organizedMatches: organized,
            currentUserId: widget.userId,
          );
        },
      ),
    );
  }
}
