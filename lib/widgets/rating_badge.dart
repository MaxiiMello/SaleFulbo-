import 'package:flutter/material.dart';

class RatingBadge extends StatelessWidget {
  const RatingBadge({
    required this.label,
    required this.rating,
    required this.icon,
    super.key,
  });

  final String label;
  final double rating;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text('$label ${rating.toStringAsFixed(1)}'),
    );
  }
}
