import 'package:flutter/foundation.dart';

class InteractionLock {
  InteractionLock._();
  static final InteractionLock instance = InteractionLock._();

  // true when cart/overlay is open and user is actively editing
  final ValueNotifier<bool> isInteracting = ValueNotifier<bool>(false);
}