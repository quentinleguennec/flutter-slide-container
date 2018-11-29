import 'package:flutter/widgets.dart';
import 'package:slide_container/slide_container.dart';

/// A controller for the [SlideContainer].
///
/// Allows you to force a slide in a given direction.
///
/// Will only work after the controller has been attached to a SlideController from a build function.
class SlideContainerController extends ChangeNotifier {
  SlideContainerDirection _forcedSlideDirection;

  SlideContainerDirection get forcedSlideDirection => _forcedSlideDirection;

  void forceSlide(SlideContainerDirection slideDirection) {
    _forcedSlideDirection = slideDirection;
    notifyListeners();
  }
}
