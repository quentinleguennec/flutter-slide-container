import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

enum VerticalSlideContainerDirection { topToBottom, bottomToTop, bidirectional }

/// Container that can be slid vertically.
///
/// Applies a dampening effect to the movement for a smoother gesture.
class VerticalSlideContainer extends StatefulWidget {
  final Widget child;

  /// Constrain the direction the container can be slid.
  final VerticalSlideContainerDirection slideDirection;

  /// When the gesture ends the animation play at this speed to move back to the start position or to [maxSlideDistance] (see [minSlideDistanceToValidate]).
  /// This takes into account the position of the container just before the gesture ends.
  ///
  /// Default to Duration(milliseconds: 300)
  final Duration autoSlideDuration;

  /// If not null the container will not slide beyond this value.
  ///
  /// Default to [MediaQueryData.size].height
  ///
  /// In px.
  final double maxSlideDistance;

  /// If the drag gesture is faster than this it will complete the slide
  ///
  /// In px/s.
  final double minDragVelocityForAutoSlide;

  /// If the drag gesture is slower than [minDragVelocityForAutoSlide] and the slide distance is less than this value then the drag is not validated and the container go back to the starting position.
  /// Else the drag is validated and the container moves to [maxSlideDistance].
  ///
  /// Default to half of [maxSlideDistance]
  ///
  /// In px.
  final double minSlideDistanceToValidate;

  /// The strength of the dampening effect when the container is moved.
  /// The bigger this value the slower the container will move toward the finger position.
  ///
  /// Needs to be superior or equal to 1.0.
  ///
  final double dampeningStrength;

  /// Called when the slide gesture starts.
  final VoidCallback onSlideStarted;

  /// Called when the slide gesture ends with a distance superior to [minSlideDistanceToValidate] or a velocity superior to [minDragVelocityForAutoSlide] (effectively triggering an auto-slide to [maxSlideDistance]).
  final VoidCallback onSlideCompleted;

  /// Called when the slide gesture ends with a value inferior or equal to [minSlideDistanceToValidate] and a velocity inferior or equal to [minDragVelocityForAutoSlide]  (effectively triggering an auto-slide to the starting position).
  final VoidCallback onSlideCanceled;

  /// Called each frame when the slide gesture is active (i.e. after [onSlideStarted] and before [onSlideCompleted] or [onSlideCanceled]) and during the auto-slide.
  /// returns the position of the slide container as a value between 0.0 and 1.0 where 0.0 means the container is at the starting position and 1.0 means the container is at [maxSlideDistance].
  final ValueChanged<double> onSlide;

  VerticalSlideContainer({
    @required this.child,
    this.slideDirection = VerticalSlideContainerDirection.bidirectional,
    this.minDragVelocityForAutoSlide = 600.0,
    this.autoSlideDuration = const Duration(milliseconds: 300),
    this.dampeningStrength = 8.0,
    this.minSlideDistanceToValidate,
    this.maxSlideDistance,
    this.onSlideStarted,
    this.onSlideCompleted,
    this.onSlideCanceled,
    this.onSlide,
  })  : assert(child != null),
        assert(minDragVelocityForAutoSlide != null),
        assert(autoSlideDuration != null),
        assert(dampeningStrength != null && dampeningStrength >= 1.0),
        assert(slideDirection != null);

  @override
  _State createState() => _State();
}

class _State extends State<VerticalSlideContainer> with TickerProviderStateMixin {
  double dragValue = 0.0;
  double dragTarget = 0.0;
  bool isFirstDragFrame;
  AnimationController animationController;
  Ticker followFingerTicker;

  double get maxDragDistance => widget.maxSlideDistance ?? MediaQuery.of(context).size.height;

  double get minDragDistanceToValidate => widget.minSlideDistanceToValidate ?? maxDragDistance * 0.5;

  @override
  void initState() {
    animationController = AnimationController(vsync: this, duration: widget.autoSlideDuration)
      ..addListener(() {
        if (widget.onSlide != null) widget.onSlide(animationController.value);
        setState(() {});
      });

    followFingerTicker = createTicker((_) {
      if ((dragValue - dragTarget).abs() <= 1.0) {
        dragTarget = dragValue;
      } else {
        /// This dampen the drag movement (acts like a spring, the farther from the finger position the faster it moves toward it).
        dragTarget += (dragValue - dragTarget) / widget.dampeningStrength;
      }
      animationController.value = dragTarget.abs() / maxDragDistance;
    });
    super.initState();
  }

  @override
  void dispose() {
    animationController?.dispose();
    followFingerTicker?.dispose();
    super.dispose();
  }

  void completeSlide() => animationController.forward().then((_) {
        if (widget.onSlideCompleted != null) widget.onSlideCompleted();
      });

  void cancelSlide() => animationController.reverse().then((_) {
        if (widget.onSlideCanceled != null) widget.onSlideCanceled();
      });

  void handlePanStart(DragStartDetails details) {
    isFirstDragFrame = true;
    dragValue = animationController.value * maxDragDistance * dragTarget.sign;
    dragTarget = dragValue;
    followFingerTicker.stop();
    followFingerTicker.start();
    if (widget.onSlideStarted != null) widget.onSlideStarted();
  }

  void handlePanUpdate(DragUpdateDetails details) {
    if (isFirstDragFrame) {
      isFirstDragFrame = false;
      return;
    }

    dragValue = (dragValue + details.delta.dy).clamp(-maxDragDistance, maxDragDistance);
    if (widget.slideDirection == VerticalSlideContainerDirection.topToBottom) {
      dragValue = dragValue.clamp(0.0, maxDragDistance);
    } else if (widget.slideDirection == VerticalSlideContainerDirection.bottomToTop) {
      dragValue = dragValue.clamp(-maxDragDistance, 0.0);
    }
  }

  void handlePanEnd(DragEndDetails details) {
    if (details.velocity.pixelsPerSecond.dy * dragTarget.sign > widget.minDragVelocityForAutoSlide) {
      completeSlide();
    } else if (details.velocity.pixelsPerSecond.dy * dragTarget.sign < -widget.minDragVelocityForAutoSlide) {
      cancelSlide();
    } else {
      dragTarget.abs() > minDragDistanceToValidate ? completeSlide() : cancelSlide();
    }
    followFingerTicker.stop();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onPanStart: handlePanStart,
        onPanUpdate: handlePanUpdate,
        onPanEnd: handlePanEnd,
        child: Transform.translate(
          offset: Offset(0.0, animationController.value * maxDragDistance * dragTarget.sign),
          child: widget.child,
        ),
      );
}
