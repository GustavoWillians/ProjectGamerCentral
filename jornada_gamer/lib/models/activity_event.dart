// lib/models/activity_event.dart

// Enum para diferenciar os tipos de evento
enum ActivityEventType { achievement, played }

class ActivityEvent {
  final String title; // Nome do Jogo
  final String description; // Descrição (Nome da conquista ou tempo jogado)
  final DateTime timestamp; // A data e hora do evento, para ordenação
  final ActivityEventType type;
  final int appId; // Para futuras imagens ou links

  ActivityEvent({
    required this.title,
    required this.description,
    required this.timestamp,
    required this.type,
    required this.appId,
  });
}