import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService {
  io.Socket? socket;

  void connect() {
    socket = io.io('http://localhost:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket!.connect();

    socket!.onConnect((_) {
      print('Connected to Socket.io server');
    });

    socket!.onDisconnect((_) {
      print('Disconnected from Socket.io server');
    });
  }

  void listenForInventoryUpdates(Function onInventoryUpdated) {
    socket!.on('inventory-updated', (_) {
      print('Inventory updated event received');
      onInventoryUpdated(); // Calls function to refresh inventory
    });
  }

  void disconnect() {
    socket!.disconnect();
  }

  void listenForLowStockWarnings(Function(Map<String, dynamic>) onLowStock) {
    socket!.on('low-stock-warning', (data) {
      print('Low-stock warning received: $data');
      onLowStock(data);
    });
  }

}
