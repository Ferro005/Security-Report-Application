import 'package:flutter/material.dart';
import '../services/notifications_service.dart';

class NotificationsPanel extends StatefulWidget {
  final int userId;
  const NotificationsPanel({super.key, required this.userId});

  @override
  State<NotificationsPanel> createState() => _NotificationsPanelState();
}

class _NotificationsPanelState extends State<NotificationsPanel> {
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await NotificationsService.getNotifications(widget.userId, limit: 100);
    setState(() {
      _notifications = items;
      _loading = false;
    });
  }

  Future<void> _markAllRead() async {
    await NotificationsService.markAllAsRead(widget.userId);
    await _load();
  }

  Future<void> _markRead(int id) async {
    await NotificationsService.markAsRead(id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Notificações',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: _markAllRead,
                        icon: const Icon(Icons.done_all),
                        label: const Text('Marcar todas como lidas'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Atualizar',
                        onPressed: _load,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _notifications.isEmpty
                      ? const Center(child: Text('Sem notificações'))
                      : ListView.separated(
                          itemCount: _notifications.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final n = _notifications[index];
                            final title = (n['title'] as String?) ?? (n['type']?.toString() ?? 'Notificação');
                            final message = (n['message'] as String?) ?? '';
                            final createdMs = (n['created_at'] as int?) ?? 0;
                            final dt = createdMs > 0
                                ? DateTime.fromMillisecondsSinceEpoch(createdMs)
                                : null;
                            final read = (n['read'] as int?) == 1;

                            return ListTile(
                              leading: Icon(
                                read ? Icons.notifications_none : Icons.notifications_active,
                                color: read ? Colors.grey : Colors.orange,
                              ),
                              title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (message.isNotEmpty) Text(message),
                                  if (dt != null)
                                    Text(
                                      dt.toString(),
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                ],
                              ),
                              trailing: read
                                  ? null
                                  : IconButton(
                                      icon: const Icon(Icons.done),
                                      tooltip: 'Marcar como lida',
                                      onPressed: () => _markRead(n['id'] as int),
                                    ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
