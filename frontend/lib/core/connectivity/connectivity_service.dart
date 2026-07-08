import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_service.g.dart';

@riverpod
ConnectivityService connectivityService(Ref ref) {
  return ConnectivityService();
}

class ConnectivityService {
  final _connectivity = Connectivity();
  final _controller = StreamController<bool>.broadcast();

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  ConnectivityService() {
    _init();
  }

  Future<void> _init() async {
    final results = await _connectivity.checkConnectivity();
    _isOnline = _resultsToOnline(results);

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final online = _resultsToOnline(results);
      if (online != _isOnline) {
        _isOnline = online;
        _controller.add(_isOnline);
      }
    });
  }

  bool _resultsToOnline(List<ConnectivityResult> results) {
    return results.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet);
  }

  Stream<bool> get onConnectivityChanged => _controller.stream;

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}

@riverpod
Stream<bool> connectivityStream(Ref ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.onConnectivityChanged;
}

@riverpod
bool isOnline(Ref ref) {
  final asyncOnline = ref.watch(connectivityStreamProvider);
  return asyncOnline.valueOrNull ??
      ref.watch(connectivityServiceProvider).isOnline;
}
