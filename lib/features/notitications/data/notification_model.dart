class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;
  final String? type;
  final Map<String, dynamic>? data;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.read = false,
    this.type,
    this.data,
  });

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        title: title,
        body: body,
        createdAt: createdAt,
        read: read ?? this.read,
        type: type,
        data: data,
      );

  factory AppNotification.fromSocket(dynamic json) {
    final Map<String, dynamic> j = (json as Map).cast<String, dynamic>();
    return AppNotification(
      id: (j['id'] ?? j['_id'] ?? DateTime.now().millisecondsSinceEpoch.toString()).toString(),
      title: (j['title'] ?? 'Notification').toString(),
      body: (j['body'] ?? '').toString(),
      createdAt: DateTime.tryParse('${j['createdAt'] ?? j['created_at'] ?? DateTime.now().toIso8601String()}') ??
          DateTime.now(),
      read: (j['read'] == true),
      type: j['type']?.toString(),
      data: (j['data'] is Map) ? (j['data'] as Map).cast<String, dynamic>() : null,
    );
  }
}