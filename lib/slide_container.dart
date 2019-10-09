import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:slide_container/extended_drag_gesture_recognizer.dart';
import 'package:slide_container/slide_container_controller.dart';

/// Direction the container can be slid from its initial position.
enum SlideContainerDirection {
  topToBottom,
  bottomToTop,
  vertical,
  leftToRight,
  rightToLeft,
  horizontal,
}

// Used by the Gesture Recognizers to know when the container can not be slid in this direction.
// This prevents the Gesture Detector to intercept and consume gesture events even when the container can not slide in the drag direction.
// This way, other gesture detectors can be used in conjunction with the SlideContainer.
enum SlideContainerLock {
  top,
  bottom,
  left,
  right,
  none,
}

/// Container that can be slid vertically or horizontally.
///
/// Applies a dampening effect to the movement for a smoother gesture.
/// Can validate slide with either drag gesture velocity or distance.
/// Will automatically finish the slide animation when the drag gesture ends.
class SlideContainer extends StatefulWidget {
  final Widget child;

  /// Constrain the direction the container can be slid.
  final SlideContainerDirection slideDirection;

  /// When the gesture ends the animation play at this speed to move back to the start position or to [maxSlideDistance] (see [minSlideDistanceToValidate]).
  /// This takes into account the position of the container just before the gesture ends.
  final Duration autoSlideDuration;

  /// The container will not slide beyond this value.
  ///
  /// Default to [MediaQueryData.size].height if the [slideDirection] is vertical and [MediaQueryData.size].width if the [slideDirection] is horizontal.
  ///
  /// In px.
  final double maxSlideDistance;

  /// If the drag gesture is faster than this it will complete the slide
  ///
  /// If set to [double.infinity] the container will not auto-slide.
  ///
  /// In px/s.
  final double minDragVelocityForAutoSlide;

  /// If the drag gesture is slower than [minDragVelocityForAutoSlide] and the slide distance is less than this value then the drag is not validated and the container go back to the starting position.
  /// Else the drag is validated and the container moves to [maxSlideDistance].
  ///
  /// If set to [double.infinity] the container will not auto-slide.
  /// Default to half of [maxSlideDistance].
  ///
  /// In px.
  final double minSlideDistanceToValidate;

  /// The strength of the dampening effect when the container is moved.
  ///
  /// The bigger this value the slower the container will move toward the finger position.
  /// A Value of 1.0 means no damping is added.
  ///
  /// Needs to be superior or equal to 1.0.
  final double dampeningStrength;

  /// Called when the slide gesture starts.
  final VoidCallback onSlideStarted;

  /// Called once when the drag distance becomes superior to [minSlideDistanceToValidate] (ending the gesture here would complete the slide).
  ///
  /// Only triggers if [minSlideDistanceToValidate] is not equal to [double.infinity] and if the slide has not yet completed.
  /// If a slide is completed because of a fast drag, the auto-slide animation will not trigger this callback.
  ///
  /// Useful to give users feedback (like haptics).
  final VoidCallback onSlideValidated;

  /// Called once after [onSlideValidated] if the drag distance becomes inferior to [minSlideDistanceToValidate] (ending the gesture here would cancel the slide).
  ///
  /// Only triggers if [minSlideDistanceToValidate] is not equal to [double.infinity] and if the slide has not yet been cancelled.
  /// If a slide is cancelled because of a fast drag, the auto-slide animation will not trigger this callback.
  ///
  /// Useful to give users feedback (like haptics).
  final VoidCallback onSlideUnvalidated;

  /// Called when:
  /// - The slide gesture ends with a distance superior to [minSlideDistanceToValidate].
  /// - The slide gesture ends with a velocity superior to [minDragVelocityForAutoSlide].
  /// - A slide is forced from the [controller] (effectively triggering an auto-slide to [maxSlideDistance]).
  final VoidCallback onSlideCompleted;

  /// Called when:
  /// - The slide gesture ends with a value inferior or equal to [minSlideDistanceToValidate] and [minSlideDistanceToValidate] is not equal to [double.infinity].
  /// - The slide gesture ends with a velocity inferior or equal to [minDragVelocityForAutoSlide] and [minDragVelocityForAutoSlide] is not equal to [double.infinity].
  /// - A slide is forced from the [controller] (effectively triggering an auto-slide to the starting position).
  final VoidCallback onSlideCanceled;

  /// Called each frame when the slide gesture is active (i.e. after [onSlideStarted] and before [onSlideCompleted] or [onSlideCanceled]) and during the auto-slide.
  ///
  /// returns the normalized position of the slide container as a value between 0.0 and 1.0 where 0.0 means the container is at the starting position and 1.0 means the container is at [maxSlideDistance].
  final ValueChanged<double> onSlide;

  /// Register this controller to be able to manually force a slide in a given direction.
  final SlideContainerController controller;

  SlideContainer({
    @required this.child,
    this.slideDirection = SlideContainerDirection.vertical,
    this.minDragVelocityForAutoSlide = 600.0,
    this.autoSlideDuration = const Duration(milliseconds: 300),
    this.dampeningStrength = 8.0,
    this.minSlideDistanceToValidate,
    this.maxSlideDistance,
    this.onSlideStarted,
    this.onSlideValidated,
    this.onSlideUnvalidated,
    this.onSlideCompleted,
    this.onSlideCanceled,
    this.onSlide,
    this.controller,
  })  : assert(child != null),
        assert(autoSlideDuration != null),
        assert(dampeningStrength != null && dampeningStrength >= 1.0),
        assert(slideDirection != null);

  @override
  _State createState() => _State();
}

class _State extends State<SlideContainer> with TickerProviderStateMixin {
  final Map<Type, GestureRecognizerFactory> gestures =
      <Type, GestureRecognizerFactory>{};

  double dragValue = 0.0;
  double dragTarget = 0.0;
  bool isFirstDragFrame = true;
  bool didValidate = false;
  bool didForceSlide = false;
  AnimationController animationController;
  Ticker followFingerTicker;

  SlideContainerController get controller => widget.controller;

  SlideContainerDirection get slideDirection => widget.slideDirection;

  bool get isVerticalSlide =>
      slideDirection == SlideContainerDirection.topToBottom ||
      slideDirection == SlideContainerDirection.bottomToTop ||
      slideDirection == SlideContainerDirection.vertical;

  double get maxDragDistance =>
      widget.maxSlideDistance ??
      (isVerticalSlide
          ? MediaQuery.of(context).size.height
          : MediaQuery.of(context).size.width);

  double get minDragDistanceToValidate =>
      widget.minSlideDistanceToValidate ?? maxDragDistance * 0.5;

  double get containerOffset =>
      animationController.value * maxDragDistance * dragTarget.sign;

  SlideContainerLock get lock {
    switch (slideDirection) {
      case SlideContainerDirection.topToBottom:
        if (containerOffset == maxDragDistance) {
          return SlideContainerLock.bottom;
        } else if (containerOffset == 0.0) {
          return SlideContainerLock.top;
        } else {
          return SlideContainerLock.none;
        }
        break;
      case SlideContainerDirection.bottomToTop:
        if (containerOffset == -maxDragDistance) {
          return SlideContainerLock.top;
        } else if (containerOffset == 0.0) {
          return SlideContainerLock.bottom;
        } else {
          return SlideContainerLock.none;
        }
        break;
      case SlideContainerDirection.vertical:
        if (containerOffset == -maxDragDistance) {
          return SlideContainerLock.top;
        } else if (containerOffset == maxDragDistance) {
          return SlideContainerLock.bottom;
        } else {
          return SlideContainerLock.none;
        }
        break;
      case SlideContainerDirection.leftToRight:
        if (containerOffset == maxDragDistance) {
          return SlideContainerLock.right;
        } else if (containerOffset == 0.0) {
          return SlideContainerLock.left;
        } else {
          return SlideContainerLock.none;
        }
        break;
      case SlideContainerDirection.rightToLeft:
        if (containerOffset == -maxDragDistance) {
          return SlideContainerLock.left;
        } else if (containerOffset == 0.0) {
          return SlideContainerLock.right;
        } else {
          return SlideContainerLock.none;
        }
        break;
      case SlideContainerDirection.horizontal:
        if (containerOffset == -maxDragDistance) {
          return SlideContainerLock.left;
        } else if (containerOffset == maxDragDistance) {
          return SlideContainerLock.right;
        } else {
          return SlideContainerLock.none;
        }
        break;
      default:
        return SlideContainerLock.none;
    }
  }

  @override
  void initState() {
    controller?.addListener(onControllerUpdated);

    animationController =
        AnimationController(vsync: this, duration: widget.autoSlideDuration)
          ..addListener(() {
            if (widget.onSlide != null)
              widget.onSlide(animationController.value);
            if (mounted) setState(() {});
          });

    followFingerTicker = createTicker((_) {
      if ((dragValue - dragTarget).abs() <= 1.0) {
        dragTarget = dragValue;
      } else {
        // This dampen the drag movement (acts like a spring, the farther from the finger position the faster it moves toward it).
        dragTarget += (dragValue - dragTarget) / widget.dampeningStrength;
      }

      if (minDragDistanceToValidate != double.infinity) {
        if (dragTarget.abs() > minDragDistanceToValidate) {
          if (!didValidate) {
            didValidate = true;
            if (widget.onSlideValidated != null) widget.onSlideValidated();
          }
        } else {
          if (didValidate) {
            didValidate = false;
            if (widget.onSlideUnvalidated != null) widget.onSlideUnvalidated();
          }
        }
      }

      animationController.value = dragTarget.abs() / maxDragDistance;
    });

    registerGestureRecognizer();

    super.initState();
  }

  @override
  void dispose() {
    animationController?.dispose();
    followFingerTicker?.dispose();
    controller?.removeListener(onControllerUpdated);
    super.dispose();
  }

  @override
  void didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.controller?.removeListener(onControllerUpdated);
    widget.controller?.addListener(onControllerUpdated);
  }

  void onControllerUpdated() {
    final SlideContainerDirection forcedSlideDirection =
        controller.forcedSlideDirection;

    assert(
        ((forcedSlideDirection == SlideContainerDirection.topToBottom ||
                        forcedSlideDirection ==
                            SlideContainerDirection.bottomToTop) &&
                    (slideDirection == SlideContainerDirection.topToBottom ||
                        slideDirection ==
                            SlideContainerDirection.bottomToTop) ||
                slideDirection == SlideContainerDirection.vertical) ||
            ((forcedSlideDirection == SlideContainerDirection.leftToRight ||
                    forcedSlideDirection ==
                        SlideContainerDirection.rightToLeft) &&
                (slideDirection == SlideContainerDirection.leftToRight ||
                    slideDirection == SlideContainerDirection.rightToLeft ||
                    slideDirection == SlideContainerDirection.horizontal)),
        "Invalid force slide direction = $forcedSlideDirection for container of directionality = $slideDirection.");

    didForceSlide = true;
    if (followFingerTicker.isActive) {
      followFingerTicker.stop();
    }

    if (containerOffset == 0.0) {
      if (forcedSlideDirection == SlideContainerDirection.topToBottom ||
          forcedSlideDirection == SlideContainerDirection.leftToRight) {
        dragTarget = 0.001;
      } else {
        dragTarget = -0.001;
      }
    }

    switch (slideDirection) {
      case SlideContainerDirection.topToBottom:
      case SlideContainerDirection.leftToRight:
      case SlideContainerDirection.bottomToTop:
      case SlideContainerDirection.rightToLeft:
        forcedSlideDirection == slideDirection
            ? completeSlide()
            : cancelSlide();
        break;
      case SlideContainerDirection.horizontal:
      case SlideContainerDirection.vertical:
        if (forcedSlideDirection == SlideContainerDirection.topToBottom ||
            forcedSlideDirection == SlideContainerDirection.leftToRight) {
          containerOffset >= 0 ? completeSlide() : cancelSlide();
        } else {
          containerOffset <= 0 ? completeSlide() : cancelSlide();
        }
    }
  }

  GestureRecognizerFactoryWithHandlers<T>
      createGestureRecognizer<T extends DragGestureRecognizer>(
              GestureRecognizerFactoryConstructor<T> constructor) =>
          GestureRecognizerFactoryWithHandlers<T>(
            constructor,
            (T instance) {
              instance
                ..onStart = handlePanStart
                ..onUpdate = handlePanUpdate
                ..onEnd = handlePanEnd;
            },
          );

  void registerGestureRecognizer() {
    if (isVerticalSlide) {
      gestures[LockableVerticalDragGestureRecognizer] =
          createGestureRecognizer<LockableVerticalDragGestureRecognizer>(() =>
              LockableVerticalDragGestureRecognizer(lockGetter: () => lock));
    } else {
      gestures[LockableHorizontalDragGestureRecognizer] =
          createGestureRecognizer<LockableHorizontalDragGestureRecognizer>(() =>
              LockableHorizontalDragGestureRecognizer(lockGetter: () => lock));
    }
  }

  double getVelocity(DragEndDetails details) => isVerticalSlide
      ? details.velocity.pixelsPerSecond.dy
      : details.velocity.pixelsPerSecond.dx;

  double getDelta(DragUpdateDetails details) =>
      isVerticalSlide ? details.delta.dy : details.delta.dx;

  void completeSlide() => animationController.forward().then((_) {
        if (widget.onSlideCompleted != null) widget.onSlideCompleted();
      });

  void cancelSlide() => animationController.reverse().then((_) {
        if (widget.onSlideCanceled != null) widget.onSlideCanceled();
      });

  void handlePanStart(DragStartDetails details) {
    didForceSlide = false;
    animationController.stop();
    isFirstDragFrame = true;
    dragValue = animationController.value * maxDragDistance * dragTarget.sign;
    dragTarget = dragValue;
    didValidate = dragTarget != 0;
    followFingerTicker.start();
    if (widget.onSlideStarted != null) widget.onSlideStarted();
  }

  void handlePanUpdate(DragUpdateDetails details) {
    if (didForceSlide) {
      return;
    }
    if (isFirstDragFrame) {
      isFirstDragFrame = false;
      return;
    }

    dragValue = (dragValue + getDelta(details))
        .clamp(-maxDragDistance, maxDragDistance);
    if (slideDirection == SlideContainerDirection.topToBottom ||
        slideDirection == SlideContainerDirection.leftToRight) {
      dragValue = dragValue.clamp(0.0, maxDragDistance);
    } else if (slideDirection == SlideContainerDirection.bottomToTop ||
        slideDirection == SlideContainerDirection.rightToLeft) {
      dragValue = dragValue.clamp(-maxDragDistance, 0.0);
    }
  }

  void handlePanEnd(DragEndDetails details) {
    if (didForceSlide) {
      return;
    }

    if (getVelocity(details) * dragTarget.sign >
        widget.minDragVelocityForAutoSlide) {
      completeSlide();
    } else if (getVelocity(details) * dragTarget.sign <
        -widget.minDragVelocityForAutoSlide) {
      cancelSlide();
    } else if (minDragDistanceToValidate != double.infinity) {
      dragTarget.abs() > minDragDistanceToValidate
          ? completeSlide()
          : cancelSlide();
    }
    followFingerTicker.stop();
  }

  @override
  Widget build(BuildContext context) => RawGestureDetector(
        gestures: gestures,
        child: Transform.translate(
          offset: isVerticalSlide
              ? Offset(
                  0.0,
                  containerOffset,
                )
              : Offset(
                  containerOffset,
                  0.0,
                ),
          child: widget.child,
        ),
      );
}
