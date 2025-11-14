class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final String type;
  final Map<String, dynamic>? metadata;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.type = 'info',
    this.metadata,
  });

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        title: title,
        message: message,
        createdAt: createdAt,
        isRead: read ?? this.isRead,
        type: type,
        metadata: metadata,
      );

  factory AppNotification.fromSocket(dynamic json) {
    final Map<String, dynamic> j = (json as Map).cast<String, dynamic>();
    return AppNotification(
      id: (j['id'] ?? DateTime.now().millisecondsSinceEpoch.toString()).toString(),
      title: (j['title'] ?? 'Notification').toString(),
      message: (j['message'] ?? j['body'] ?? '').toString(),
      createdAt: DateTime.tryParse(j['createdAt'] ?? DateTime.now().toIso8601String()) ?? DateTime.now(),
      isRead: (j['isRead'] == true) || (j['read'] == true),
      type: j['type']?.toString() ?? 'info',
      metadata: (j['metadata'] is Map) ? (j['metadata'] as Map).cast<String, dynamic>() : null,
    );
  }

  // Helper to get notification color based on type
  String getIconName() {
    switch (type.toLowerCase()) {
      case 'success':
        return 'check_circle';
      case 'warning':
        return 'warning';
      case 'error':
        return 'error';
      default:
        return 'info';
    }
  }
}