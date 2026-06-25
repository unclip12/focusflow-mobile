import 'package:objectbox/objectbox.dart';

@Entity()
class DocumentVector {
  @Id()
  int id = 0;

  String text;
  String sourceId; // e.g., Task ID or Note ID to link back
  String sourceType; // e.g., 'task', 'note', 'schedule'

  @HnswIndex(dimensions: 384)
  @Property(type: PropertyType.floatVector)
  List<double>? embedding;

  DocumentVector({
    this.id = 0,
    required this.text,
    required this.sourceId,
    required this.sourceType,
    this.embedding,
  });
}
