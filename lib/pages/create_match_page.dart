import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/app_user.dart';
import '../models/court_suggestion.dart';
import '../models/match_post.dart';
import '../services/court_search_service.dart';

class CreateMatchPage extends StatefulWidget {
  const CreateMatchPage({required this.currentUser, super.key});

  final AppUser currentUser;

  @override
  State<CreateMatchPage> createState() => _CreateMatchPageState();
}

class _CreateMatchPageState extends State<CreateMatchPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _courtController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  final CourtSearchService _courtSearchService = CourtSearchService();

  FootballFormat _format = FootballFormat.five;
  late int _totalPlayers;
  int _missingPlayers = 1;
  MatchIntensity _intensity = MatchIntensity.tranquilo;
  DateTime _scheduledAt = DateTime.now().add(const Duration(hours: 1));
  double? _selectedLatitude;
  double? _selectedLongitude;
  Position? _currentPosition;
  List<CourtSuggestion> _suggestions = <CourtSuggestion>[];
  bool _searchingCourts = false;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _totalPlayers = expectedPlayersForFormat(_format);
    _loadPosition();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _titleController.dispose();
    _courtController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadPosition() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final Position pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _currentPosition = pos;
      });
    } catch (_) {
      // Ignore and fallback to default coordinates on submit.
    }
  }

  void _onCourtQueryChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _searchCourts(value);
    });
  }

  Future<void> _searchCourts(String query) async {
    if (query.trim().length < 2) {
      if (!mounted) return;
      setState(() {
        _suggestions = <CourtSuggestion>[];
        _searchingCourts = false;
      });
      return;
    }

    final double baseLat = CourtSearchService.riveraLivramentoCenterLat;
    final double baseLon = CourtSearchService.riveraLivramentoCenterLon;

    setState(() {
      _searchingCourts = true;
    });

    final List<CourtSuggestion> results = await _courtSearchService.searchNearbyCourts(
      query: query,
      userLatitude: baseLat,
      userLongitude: baseLon,
      radiusKm: 15,
    );

    if (!mounted) return;
    setState(() {
      _suggestions = results;
      _searchingCourts = false;
    });
  }

  void _applySuggestion(CourtSuggestion suggestion) {
    setState(() {
      _courtController.text = suggestion.name;
      _selectedLatitude = suggestion.latitude;
      _selectedLongitude = suggestion.longitude;
      _suggestions = <CourtSuggestion>[];
    });
  }

  Future<void> _pickSchedule() async {
    final DateTime now = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _scheduledAt,
      firstDate: now,
      lastDate: now.add(const Duration(days: 180)),
    );
    if (pickedDate == null || !mounted) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
    );
    if (pickedTime == null || !mounted) return;

    setState(() {
      _scheduledAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  String _formatSchedule(DateTime value) {
    final String dd = value.day.toString().padLeft(2, '0');
    final String mm = value.month.toString().padLeft(2, '0');
    final String yyyy = value.year.toString();
    final String hh = value.hour.toString().padLeft(2, '0');
    final String min = value.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy - $hh:$min';
  }

  void _submit() {
    final bool valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    final double latitude =
        _selectedLatitude ?? _currentPosition?.latitude ?? -30.9015;
    final double longitude =
        _selectedLongitude ?? _currentPosition?.longitude ?? -55.5507;

    final MatchPost match = MatchPost(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      createdByUserId: widget.currentUser.id,
      createdByName: widget.currentUser.displayName,
      title: _titleController.text.trim(),
      courtName: _courtController.text.trim(),
      totalPlayers: _totalPlayers,
      missingPlayers: _missingPlayers,
      latitude: latitude,
      longitude: longitude,
      scheduledAt: _scheduledAt,
      isClosed: false,
      format: _format,
      intensity: _intensity,
      pricePerPlayer: double.parse(_priceController.text.trim()),
      creatorRating: 4.8,
      playerRating: 4.6,
    );

    Navigator.of(context).pop<MatchPost>(match);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear partido')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: <Widget>[
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titulo',
              ),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _courtController,
              onChanged: _onCourtQueryChanged,
              decoration: const InputDecoration(
                labelText: 'Cancha',
                hintText: 'Busca por nombre o abreviacion',
              ),
              validator: _requiredValidator,
            ),
            if (_searchingCourts)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            if (_suggestions.isNotEmpty)
              Card(
                margin: const EdgeInsets.only(top: 8),
                child: Column(
                  children: _suggestions.take(6).map((CourtSuggestion suggestion) {
                    return ListTile(
                      dense: true,
                      title: Text(suggestion.name),
                      subtitle: Text('${suggestion.distanceKm.toStringAsFixed(1)} km - ${suggestion.source}'),
                      onTap: () => _applySuggestion(suggestion),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Horario del partido'),
              subtitle: Text(_formatSchedule(_scheduledAt)),
              trailing: const Icon(Icons.schedule),
              onTap: _pickSchedule,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Precio por jugador',
                prefixText: '\$ ',
              ),
              validator: _numberValidator,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<FootballFormat>(
              initialValue: _format,
              decoration: const InputDecoration(labelText: 'Categoria'),
              items: FootballFormat.values.map((FootballFormat value) {
                return DropdownMenuItem<FootballFormat>(
                  value: value,
                  child: Text(footballFormatLabel(value)),
                );
              }).toList(),
              onChanged: (FootballFormat? value) {
                if (value == null) return;
                setState(() {
                  _format = value;
                  _totalPlayers = expectedPlayersForFormat(value);
                  _missingPlayers = _missingPlayers.clamp(1, _totalPlayers);
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<MatchIntensity>(
              initialValue: _intensity,
              decoration: const InputDecoration(labelText: 'Intensidad'),
              items: MatchIntensity.values.map((MatchIntensity value) {
                return DropdownMenuItem<MatchIntensity>(
                  value: value,
                  child: Text(intensityLabel(value)),
                );
              }).toList(),
              onChanged: (MatchIntensity? value) {
                if (value == null) return;
                setState(() {
                  _intensity = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Text('Jugadores totales: $_totalPlayers'),
            const SizedBox(height: 8),
            Text('Cuantos faltan: $_missingPlayers'),
            Slider(
              value: _missingPlayers.toDouble(),
              min: 1,
              max: _totalPlayers.toDouble(),
              divisions: _totalPlayers - 1,
              label: '$_missingPlayers',
              onChanged: (double value) {
                setState(() {
                  _missingPlayers = value.round();
                });
              },
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Publicar partido'),
            ),
          ],
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return 'Campo obligatorio';
    }
    return null;
  }

  String? _numberValidator(String? value) {
    final String raw = (value ?? '').trim();
    if (raw.isEmpty) {
      return 'Campo obligatorio';
    }
    if (double.tryParse(raw) == null) {
      return 'Numero invalido';
    }
    return null;
  }
}
