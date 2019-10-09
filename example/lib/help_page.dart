import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:slide_container/slide_container.dart';
import 'package:slide_container/slide_container_controller.dart';

class HelpPage extends PopupRoute<Null> {
  @override
  Color get barrierColor => null;

  @override
  bool get barrierDismissible => false;

  /// If this is true the page bellow will not be visible when sliding.
  @override
  bool get opaque => false;

  @override
  String get barrierLabel => "Close";

  @override
  Duration get transitionDuration => const Duration(microseconds: 1);

  @override
  Widget buildPage(_, __, ___) => _PageLayout();
}

class _PageLayout extends StatefulWidget {
  _PageLayout();

  @override
  _PageLayoutState createState() => _PageLayoutState();
}

class _PageLayoutState extends State<_PageLayout> {
  final SlideContainerController slideContainerController =
      SlideContainerController();

  Widget get lineSeparator => Container(
        margin: const EdgeInsets.only(top: 10, bottom: 10),
        width: 47.0,
        height: 0.5,
        color: Colors.black,
      );

  @override
  Widget build(BuildContext context) => WillPopScope(
        onWillPop: () async {
          slideContainerController
              .forceSlide(SlideContainerDirection.topToBottom);
          return false;
        },
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: _ClosePageSlideContainer(
            controller: slideContainerController,
            child: Container(
              constraints: BoxConstraints.tight(MediaQuery.of(context).size),
              padding: MediaQuery.of(context).padding +
                  EdgeInsets.only(top: 20, left: 20, right: 20),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  const Text(
                    "Welcome to SlideContainer!",
                    style: TextStyle(fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                  lineSeparator,
                  const Text(
                    "This example app covers several aspects of the SlideContainer.",
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  lineSeparator,
                  const Text(
                    "On the main page the bottom nav bar as several options, check the source code for more info:" +
                        "\n\t- 1: Simple example where both SlideContainers can be manually slid and the bottom one also slide by itself using a SlideContainerController." +
                        "\n\t- 2: Example showing a limitation in Flutter affecting Gesture hit test detection and how to work around it." +
                        "\n\t- 3: Example of use of SlideContainers as side menus.",
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.start,
                  ),
                  lineSeparator,
                  const Text(
                    "The page you are currently looking at is in a SlideContainer, you can slide it from top to bottom to pop it and reveal the underlying page.",
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

/// Handy version of the [SlideContainer] to pop pages with a slide.
class _ClosePageSlideContainer extends StatefulWidget {
  final Widget child;
  final VoidCallback onSlideStarted;
  final VoidCallback onSlideCompleted;
  final VoidCallback onSlideCanceled;
  final ValueChanged<double> onSlide;
  final SlideContainerController controller;

  _ClosePageSlideContainer({
    @required this.child,
    this.onSlideStarted,
    this.onSlideCompleted,
    this.onSlideCanceled,
    this.onSlide,
    this.controller,
  });

  @override
  _ClosePageSlideContainerState createState() =>
      _ClosePageSlideContainerState();
}

class _ClosePageSlideContainerState extends State<_ClosePageSlideContainer> {
  double overlayOpacity = 1.0;

  double get maxSlideDistance => MediaQuery.of(context).size.height;

  double get minSlideDistanceToValidate => maxSlideDistance * 0.5;

  void onSlide(double verticalPosition) {
    if (mounted) {
      setState(() => overlayOpacity = (1.000912 -
              0.1701771 * verticalPosition +
              1.676138 * pow(verticalPosition, 2) -
              3.784127 * pow(verticalPosition, 3))
          .clamp(0.0, 1.0));
    }
    if (widget.onSlide != null) widget.onSlide(verticalPosition);
  }

  void onSlideCompleted() {
    if (widget.onSlideCompleted != null) widget.onSlideCompleted();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => SlideContainer(
        controller: widget.controller,
        slideDirection: SlideContainerDirection.topToBottom,
        onSlide: onSlide,
        onSlideCompleted: onSlideCompleted,
        minDragVelocityForAutoSlide: 600.0,
        minSlideDistanceToValidate: minSlideDistanceToValidate,
        maxSlideDistance: maxSlideDistance,
        autoSlideDuration: const Duration(milliseconds: 300),
        onSlideStarted: widget.onSlideStarted,
        onSlideCanceled: widget.onSlideCanceled,
        onSlideValidated: () => HapticFeedback.mediumImpact(),
        child: Opacity(
          opacity: overlayOpacity,
          child: widget.child,
        ),
      );
}
