import 'package:logging/logging.dart';
import 'package:signalr_netcore/signalr_client.dart';

class SignalRService {
  // Singleton
  static final SignalRService _instance = SignalRService._internal();
  factory SignalRService() => _instance;
  SignalRService._internal();

  static const String _hubUrl = 'http://localhost:5225/matchHub';

  HubConnection? _hubConnection;

  void Function(String matchedUserId)? onMatchReceived;

  Future<void> connect(String userId) async {
    await disconnect();

    final logger = Logger('SignalR');

    _hubConnection =
        HubConnectionBuilder()
            .withUrl(_hubUrl)
            .withAutomaticReconnect()
            .configureLogging(logger)
            .build();

    _hubConnection!.on('ReceiveMatchNotification', (arguments) {
      print('SR: ReceiveMatchNotification args: $arguments');
      if (arguments != null && arguments.isNotEmpty) {
        final matchedUserId = arguments[0]?.toString();
        if (matchedUserId != null && matchedUserId.isNotEmpty) {
          print('SR: Match notification → matchedUserId: $matchedUserId');
          onMatchReceived?.call(matchedUserId);
        }
      }
    });

    _hubConnection!.onclose(({error}) {
      print('SR: Connection closed: $error');
    });

    _hubConnection!.onreconnecting(({error}) {
      print('SR: Reconnecting: $error');
    });

    _hubConnection!.onreconnected(({connectionId}) {
      print('SR: Reconnected: $connectionId');
      _hubConnection?.invoke('Subscribe', args: [userId]);
    });

    try {
      await _hubConnection!.start();
      print('SR: Connected: ${_hubConnection!.connectionId}');
      await _hubConnection!.invoke('Subscribe', args: [userId]);
      print('SR: Subscribed to group: $userId');
    } catch (e) {
      print('SR: Connection/Subscribe failed: $e');
    }
  }

  Future<void> disconnect() async {
    if (_hubConnection != null) {
      try {
        await _hubConnection!.stop();
      } catch (_) {}
      _hubConnection = null;
    }
  }
}
