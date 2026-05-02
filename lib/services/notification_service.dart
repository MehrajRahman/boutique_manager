import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(settings);
  }

  Future<void> showLowStockAlert({
    required String productName,
    required int quantity,
  }) async {
    await _plugin.show(
      productName.hashCode,
      'Low Stock Alert',
      '$productName is running low — only $quantity left!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'low_stock_channel',
          'Low Stock Alerts',
          channelDescription: 'Notifications for low stock items',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> showSyncComplete(int count) async {
    await _plugin.show(
      0,
      'Sync Complete',
      'Successfully synced $count items to cloud.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'sync_channel',
          'Sync Notifications',
          channelDescription: 'Notifications for cloud sync',
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
