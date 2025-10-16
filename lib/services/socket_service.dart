import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService {
  SocketService._privateConstructor();
  static final SocketService instance = SocketService._privateConstructor();

  late io.Socket socket;

  void connect(String url) {
    socket = io.io(url, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.onConnect((_) {
      print("Connected to socket server");
    });
  }

  void on(String event, Function(dynamic) callback) {
    socket.on(event, callback);
  }

  void emit(String event, dynamic data) {
    socket.emit(event, data);
  }
}
