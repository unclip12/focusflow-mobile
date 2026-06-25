import 'package:flutter/material.dart';

class ScreenAwarenessService extends RouteObserver<PageRoute<dynamic>> {
  static final ScreenAwarenessService _instance = ScreenAwarenessService._internal();
  factory ScreenAwarenessService() => _instance;
  ScreenAwarenessService._internal();

  String _currentContext = 'Home Screen';

  String get currentContext => _currentContext;

  void updateContext(String contextDesc) {
    _currentContext = contextDesc;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route is PageRoute) {
      _currentContext = 'Viewing ${route.settings.name ?? 'unknown page'}';
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute is PageRoute) {
      _currentContext = 'Viewing ${previousRoute.settings.name ?? 'unknown page'}';
    }
  }
}
