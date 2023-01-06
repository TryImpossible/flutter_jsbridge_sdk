typedef JSBridgeHandler<T extends Object?> = Future<T> Function(Object? data);

typedef JSBridgeMessageEmitter = Future<void> Function(String javascriptString);

typedef JSBridgeMessageHandler = void Function(String javascriptString);
