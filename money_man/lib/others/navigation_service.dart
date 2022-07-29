import 'package:flutter/widgets.dart';

class NavigationService {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<dynamic> pushNamed(String routeName, {dynamic argument}) {
    return navigatorKey.currentState.pushNamed(routeName, arguments: argument);
  }

  Future<dynamic> pushReplacementNamed(String routeName, {dynamic argument}) {
    return navigatorKey.currentState
        .pushReplacementNamed(routeName, arguments: argument);
  }

  Future<dynamic> pushNamedAndRemoveUntil(String routeName,
      {dynamic argument, RoutePredicate predicate}) {
    return navigatorKey.currentState.pushNamedAndRemoveUntil(
      routeName,
      predicate != null ? predicate : (Route<dynamic> route) => false,
      arguments: argument,
    );
  }

  void pop({dynamic value}) {
    return navigatorKey.currentState.pop(value);
  }
}
