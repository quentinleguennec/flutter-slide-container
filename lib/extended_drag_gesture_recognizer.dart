import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:slide_container/slide_container.dart';

/// Recognizes movement in the vertical direction.
///
/// Modified version of the [VerticalDragGestureRecognizer] that can be locked to prevent up or down movement.
/// Movements in the locked direction will not trigger a gesture and thus not block other gesture detectors.
class LockableVerticalDragGestureRecognizer
    extends ExtendedDragGestureRecognizer {
  /// Getter to know if the movement should be blocked in one direction.
  final ValueGetter<SlideContainerLock> lockGetter;

  LockableVerticalDragGestureRecognizer({
    @required this.lockGetter,
    Object debugOwner,
  })  : assert(lockGetter != null),
        super(debugOwner: debugOwner);

  SlideContainerLock get lock => lockGetter();

  @override
  bool _isFlingGesture(VelocityEstimate estimate) {
    final double minVelocity = minFlingVelocity ?? kMinFlingVelocity;
    final double minDistance = minFlingDistance ?? kTouchSlop;
    if ((lock == SlideContainerLock.top && estimate.pixelsPerSecond.dy < 0.0) ||
        (lock == SlideContainerLock.bottom &&
            estimate.pixelsPerSecond.dy > 0.0)) {
      return false;
    }
    return estimate.pixelsPerSecond.dy.abs() > minVelocity &&
        estimate.offset.dy.abs() > minDistance;
  }

  @override
  bool get _hasSufficientPendingDragDeltaToAccept {
    if ((lock == SlideContainerLock.top && _pendingDragOffset.dy < 0.0) ||
        (lock == SlideContainerLock.bottom && _pendingDragOffset.dy > 0.0)) {
      return false;
    }
    return _pendingDragOffset.dy.abs() > kTouchSlop;
  }

  @override
  Offset _getDeltaForDetails(Offset delta) => Offset(0.0, delta.dy);

  @override
  double _getPrimaryValueFromOffset(Offset value) => value.dy;

  @override
  String get debugDescription => 'lockable vertical drag';
}

/// Recognizes movement in the horizontal direction.
///
/// Modified version of the [HorizontalDragGestureRecognizer] that can be locked to prevent left or right movement.
/// Movements in the locked direction will not trigger a gesture and thus not block other gesture detectors.
class LockableHorizontalDragGestureRecognizer
    extends ExtendedDragGestureRecognizer {
  /// Getter to know if the movement should be blocked in one direction.
  final ValueGetter<SlideContainerLock> lockGetter;

  LockableHorizontalDragGestureRecognizer({
    @required this.lockGetter,
    Object debugOwner,
  })  : assert(lockGetter != null),
        super(debugOwner: debugOwner);

  SlideContainerLock get lock => lockGetter();

  @override
  bool _isFlingGesture(VelocityEstimate estimate) {
    final double minVelocity = minFlingVelocity ?? kMinFlingVelocity;
    final double minDistance = minFlingDistance ?? kTouchSlop;
    if ((lock == SlideContainerLock.left &&
            estimate.pixelsPerSecond.dx < 0.0) ||
        (lock == SlideContainerLock.right &&
            estimate.pixelsPerSecond.dx > 0.0)) {
      return false;
    }
    return estimate.pixelsPerSecond.dx.abs() > minVelocity &&
        estimate.offset.dx.abs() > minDistance;
  }

  @override
  bool get _hasSufficientPendingDragDeltaToAccept {
    if ((lock == SlideContainerLock.left && _pendingDragOffset.dx < 0.0) ||
        (lock == SlideContainerLock.right && _pendingDragOffset.dx > 0.0)) {
      return false;
    }
    return _pendingDragOffset.dx.abs() > kTouchSlop;
  }

  @override
  Offset _getDeltaForDetails(Offset delta) => Offset(delta.dx, 0.0);

  @override
  double _getPrimaryValueFromOffset(Offset value) => value.dx;

  @override
  String get debugDescription => 'lockable horizontal drag';
}

enum _DragState {
  ready,
  possible,
  accepted,
}

/// Copy-paste of Flutter's [DragGestureRecognizer] to get access to the private elements.
abstract class ExtendedDragGestureRecognizer extends DragGestureRecognizer {
  ExtendedDragGestureRecognizer({Object debugOwner})
      : super(debugOwner: debugOwner);
  GestureDragDownCallback onDown;
  GestureDragStartCallback onStart;
  GestureDragUpdateCallback onUpdate;
  GestureDragEndCallback onEnd;
  GestureDragCancelCallback onCancel;
  double minFlingDistance;
  double minFlingVelocity;
  double maxFlingVelocity;

  _DragState _state = _DragState.ready;
  Offset _initialPosition;
  Offset _pendingDragOffset;
  Duration _lastPendingEventTimestamp;

  bool _isFlingGesture(VelocityEstimate estimate);

  Offset _getDeltaForDetails(Offset delta);

  double _getPrimaryValueFromOffset(Offset value);

  bool get _hasSufficientPendingDragDeltaToAccept;

  final Map<int, VelocityTracker> _velocityTrackers = <int, VelocityTracker>{};

  @override
  void addPointer(PointerEvent event) {
    startTrackingPointer(event.pointer);
    _velocityTrackers[event.pointer] = VelocityTracker();
    if (_state == _DragState.ready) {
      _state = _DragState.possible;
      _initialPosition = event.position;
      _pendingDragOffset = Offset.zero;
      _lastPendingEventTimestamp = event.timeStamp;
      if (onDown != null)
        invokeCallback<void>('onDown',
            () => onDown(DragDownDetails(globalPosition: _initialPosition)));
    } else if (_state == _DragState.accepted) {
      resolve(GestureDisposition.accepted);
    }
  }

  @override
  void handleEvent(PointerEvent event) {
    assert(_state != _DragState.ready);
    if (!event.synthesized &&
        (event is PointerDownEvent || event is PointerMoveEvent)) {
      final VelocityTracker tracker = _velocityTrackers[event.pointer];
      assert(tracker != null);
      tracker.addPosition(event.timeStamp, event.position);
    }

    if (event is PointerMoveEvent) {
      final Offset delta = event.delta;
      if (_state == _DragState.accepted) {
        if (onUpdate != null) {
          invokeCallback<void>(
              'onUpdate',
              () => onUpdate(DragUpdateDetails(
                    sourceTimeStamp: event.timeStamp,
                    delta: _getDeltaForDetails(delta),
                    primaryDelta: _getPrimaryValueFromOffset(delta),
                    globalPosition: event.position,
                  )));
        }
      } else {
        _pendingDragOffset += delta;
        _lastPendingEventTimestamp = event.timeStamp;
        if (_hasSufficientPendingDragDeltaToAccept)
          resolve(GestureDisposition.accepted);
      }
    }
    stopTrackingIfPointerNoLongerDown(event);
  }

  @override
  void acceptGesture(int pointer) {
    if (_state != _DragState.accepted) {
      _state = _DragState.accepted;
      final Offset delta = _pendingDragOffset;
      final Duration timestamp = _lastPendingEventTimestamp;
      _pendingDragOffset = Offset.zero;
      _lastPendingEventTimestamp = null;
      if (onStart != null) {
        invokeCallback<void>(
            'onStart',
            () => onStart(DragStartDetails(
                  sourceTimeStamp: timestamp,
                  globalPosition: _initialPosition,
                )));
      }
      if (delta != Offset.zero && onUpdate != null) {
        final Offset deltaForDetails = _getDeltaForDetails(delta);
        invokeCallback<void>(
            'onUpdate',
            () => onUpdate(DragUpdateDetails(
                  sourceTimeStamp: timestamp,
                  delta: deltaForDetails,
                  primaryDelta: _getPrimaryValueFromOffset(delta),
                  globalPosition: _initialPosition + deltaForDetails,
                )));
      }
    }
  }

  @override
  void rejectGesture(int pointer) {
    stopTrackingPointer(pointer);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    if (_state == _DragState.possible) {
      resolve(GestureDisposition.rejected);
      _state = _DragState.ready;
      if (onCancel != null) invokeCallback<void>('onCancel', onCancel);
      return;
    }
    final bool wasAccepted = _state == _DragState.accepted;
    _state = _DragState.ready;
    if (wasAccepted && onEnd != null) {
      final VelocityTracker tracker = _velocityTrackers[pointer];
      assert(tracker != null);

      final VelocityEstimate estimate = tracker.getVelocityEstimate();
      if (estimate != null && _isFlingGesture(estimate)) {
        final Velocity velocity =
            Velocity(pixelsPerSecond: estimate.pixelsPerSecond).clampMagnitude(
                minFlingVelocity ?? kMinFlingVelocity,
                maxFlingVelocity ?? kMaxFlingVelocity);
        invokeCallback<void>(
            'onEnd',
            () => onEnd(DragEndDetails(
                  velocity: velocity,
                  primaryVelocity:
                      _getPrimaryValueFromOffset(velocity.pixelsPerSecond),
                )), debugReport: () {
          return '$estimate; fling at $velocity.';
        });
      } else {
        invokeCallback<void>(
            'onEnd',
            () => onEnd(DragEndDetails(
                  velocity: Velocity.zero,
                  primaryVelocity: 0.0,
                )), debugReport: () {
          if (estimate == null) return 'Could not estimate velocity.';
          return '$estimate; judged to not be a fling.';
        });
      }
    }
    _velocityTrackers.clear();
  }

  @override
  void dispose() {
    _velocityTrackers.clear();
    super.dispose();
  }
}
