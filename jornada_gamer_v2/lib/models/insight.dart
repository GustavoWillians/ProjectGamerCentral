// lib/models/insight.dart

enum InsightType { text, comparison }

class Insight {
  final String title;
  final String description;
  final InsightType type;
  final Map<String, double>? data; // Para guardar dados de comparação

  Insight({
    required this.title,
    required this.description,
    this.type = InsightType.text,
    this.data,
  });
}