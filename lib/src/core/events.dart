/// Mixin for objects that emit named events with arbitrary payloads.
///
/// Mirrors `Matter.Events` in matter-js.
mixin Eventful {
  final Map<String, List<void Function(Map<String, dynamic>)>> _eventListeners = {};

  /// Subscribes `callback` to one or more space-separated event names.
  void on(String eventNames, void Function(Map<String, dynamic>) callback) {
    for (final name in eventNames.split(' ')) {
      if (name.isEmpty) continue;
      _eventListeners.putIfAbsent(name, () => []).add(callback);
    }
  }

  /// Removes listener(s). If `callback` is null, removes all listeners for the
  /// given event names. If `eventNames` is null, removes all listeners.
  void off([String? eventNames, void Function(Map<String, dynamic>)? callback]) {
    if (eventNames == null) {
      _eventListeners.clear();
      return;
    }
    for (final name in eventNames.split(' ')) {
      if (name.isEmpty) continue;
      if (callback == null) {
        _eventListeners.remove(name);
      } else {
        _eventListeners[name]?.remove(callback);
      }
    }
  }

  /// Fires named events, passing `event` (defaults to empty map) to each listener.
  void trigger(String eventNames, [Map<String, dynamic>? event]) {
    final payload = event ?? <String, dynamic>{};
    for (final name in eventNames.split(' ')) {
      if (name.isEmpty) continue;
      final listeners = _eventListeners[name];
      if (listeners == null) continue;
      for (final cb in List.of(listeners)) {
        cb({...payload, 'name': name, 'source': this});
      }
    }
  }
}
