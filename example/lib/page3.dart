import 'package:flutter/material.dart';
import 'package:slide_container/slide_container.dart';
import 'package:slide_container/slide_container_controller.dart';

/// This example shows of the [SlideContainer] can be used as a side menu. And demonstrate how to
/// disable the auto-slide.
class Page3 extends StatefulWidget {
  @override
  _State createState() => _State();
}

class _State extends State<Page3> {
  static const double menuBarHeight = 64;
  final SlideContainerController controller = SlideContainerController();

  bool isMenuExtended = false;

  double get maxSlideDistance =>
      MediaQuery.of(context).size.width - menuBarHeight;

  BoxDecoration get containerDecoration => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xfffddb92),
            const Color(0xffd1fdff),
          ],
        ),
        boxShadow: [
          const BoxShadow(
            color: Color(0x90000000),
            blurRadius: 10.0,
            spreadRadius: 5.0,
          ),
        ],
      );

  Widget get menuWithoutAutoSlide => Positioned(
        top: MediaQuery.of(context).size.height * 0.6,
        width: MediaQuery.of(context).size.width,
        height: menuBarHeight,
        child: Transform.translate(
          offset: Offset(-maxSlideDistance, 0),
          child: SlideContainer(
            slideDirection: SlideContainerDirection.leftToRight,

            /// Setting the following two to double.infinity will fully disable the auto-slide
            /// (they can also be disabled separately).
            minSlideDistanceToValidate: double.infinity,
            minDragVelocityForAutoSlide: double.infinity,
            maxSlideDistance: maxSlideDistance,
            child: Container(
              alignment: Alignment.center,
              decoration: containerDecoration,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Text(
                      "Without auto-slide",
                      style: TextStyle(fontSize: 26.0),
                    ),
                  ),
                  Container(
                    width: menuBarHeight,
                    height: menuBarHeight,
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 24.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget get menuWithAutoSlide => Positioned(
        top: MediaQuery.of(context).size.height * 0.4,
        width: MediaQuery.of(context).size.width,
        height: menuBarHeight,
        child: Transform.translate(
          offset: Offset(maxSlideDistance, 0),
          child: SlideContainer(
            slideDirection: SlideContainerDirection.rightToLeft,
            maxSlideDistance: maxSlideDistance,
            child: Container(
              alignment: Alignment.center,
              decoration: containerDecoration,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Container(
                    width: menuBarHeight,
                    height: menuBarHeight,
                    child: Icon(
                      Icons.arrow_back_ios,
                      size: 24.0,
                    ),
                  ),
                  const Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: Text(
                      "With auto-slide",
                      style: TextStyle(fontSize: 26.0),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget get menuWithTapGesture => Positioned(
        top: MediaQuery.of(context).size.height * 0.2,
        width: MediaQuery.of(context).size.width,
        height: menuBarHeight,
        child: Transform.translate(
          offset: Offset(-maxSlideDistance, 0),
          child: SlideContainer(
            slideDirection: SlideContainerDirection.leftToRight,
            maxSlideDistance: maxSlideDistance,
            controller: controller,
            onSlideCompleted: () => isMenuExtended = true,
            onSlideCanceled: () => isMenuExtended = false,
            child: Container(
              alignment: Alignment.center,
              decoration: containerDecoration,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  GestureDetector(
                    onTap: () => print("onTap"),
                    child: const Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: Text(
                        "With tap to slide",
                        style: TextStyle(fontSize: 26.0),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      isMenuExtended
                          ? controller
                              .forceSlide(SlideContainerDirection.rightToLeft)
                          : controller
                              .forceSlide(SlideContainerDirection.leftToRight);
                    },
                    child: Container(
                      width: menuBarHeight,
                      height: menuBarHeight,
                      color: Colors.transparent,
                      child: Icon(
                        Icons.arrow_forward_ios,
                        size: 24.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Container(
        constraints: BoxConstraints.expand(),
        child: Stack(
          children: <Widget>[
            menuWithoutAutoSlide,
            menuWithAutoSlide,
            menuWithTapGesture,
          ],
        ),
      );
}
