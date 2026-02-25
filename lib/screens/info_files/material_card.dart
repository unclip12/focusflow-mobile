// =============================================================
// MaterialCard â€” grid card for study material
// Type icon, title, source chip, date, tap handler.
// =============================================================

import 'package:flutter/material.dart';

import 'package:focusflow_mobile/models/study_material.dart';

class MaterialCard extends StatelessWidget {
  final StudyMaterial material;
  final VoidCallback? onTap;

  const MaterialCard({
    super.key,
    required this.material,
    this.onTap,
  });

  IconData _typeIcon(String type) {
    switch (type.toUpperCase()) {
      case 'PDF':   return Icons.picture_as_pdf_rounded;
      case 'IMAGE': return Icons.image_rounded;
      case 'TEXT':   return Icons.article_rounded;
      default:       return Icons.insert_drive_file_rounded;
    }
  }

  Color _typeColor(String type) {
    switch (type.toUpperCase()) {
      case 'PDF':   return const Color(0xFFEF4444);
      case 'IMAGE': return const Color(0xFF3B82F6);
      case 'TEXT':   return const Color(0xFF10B981);
      default:       return const Color(0xFF94A3B8);
    }
  }

  String _typeLabel(String type) {
    switch (type.toUpperCase()) {
      case 'PDF':   return 'PDF';
      case 'IMAGE': return 'Image';
      case 'TEXT':   return 'Notes';
      default:       return type;
    }
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;
    final color = _typeColor(material.sourceType);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:        cs.surface,
          borderRadius: BorderRadius.circular(14),
          border:       Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset:     const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // â”€â”€ Type icon â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:        color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_typeIcon(material.sourceType),
                  size: 22, color: color),
            ),
            const SizedBox(height: 10),

            // â”€â”€ Title â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Text(
              material.title,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),

            // â”€â”€ Type chip + date â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color:        color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _typeLabel(material.sourceType),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color:      color,
                      fontWeight: FontWeight.w700,
                      fontSize:   10,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(material.createdAt),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color:    cs.onSurface.withValues(alpha: 0.35),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
