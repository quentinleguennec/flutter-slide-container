import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:slide_container/slide_container.dart';
import 'package:slide_container/slide_container_controller.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Scaffold(
          body: _Body(),
        ),
      );
}

class _Body extends StatefulWidget {
  @override
  _State createState() => _State();
}

class _State extends State<_Body> {
  final SlideContainerController controller = SlideContainerController();

  double position = 0.0;

  double get maxSlideDistance => MediaQuery.of(context).size.height * 0.2;

  @override
  void initState() {
    /// This will not do anything because [build()] as not been called yet and thus the controller is not attached to any [SlideContainer]
    controller.forceSlide(SlideContainerDirection.rightToLeft);

    playForceSlideLoop();
    super.initState();
  }

  void playForceSlideLoop() {
    Future.delayed(Duration(seconds: 3), () {
      controller.forceSlide(SlideContainerDirection.leftToRight);
      Future.delayed(Duration(seconds: 3), () {
        controller.forceSlide(SlideContainerDirection.leftToRight);
        Future.delayed(Duration(seconds: 3), () {
          controller.forceSlide(SlideContainerDirection.rightToLeft);
          Future.delayed(Duration(seconds: 3), () {
            controller.forceSlide(SlideContainerDirection.rightToLeft);
            playForceSlideLoop();
          });
        });
      });
    });
  }

  void onSlide(double position) {
    setState(() => this.position = position);
  }

  @override
  Widget build(BuildContext context) => Container(
        constraints: BoxConstraints.expand(),
        child: Stack(
          children: <Widget>[
            Positioned(
              top: MediaQuery.of(context).size.height * 0.07,
              width: MediaQuery.of(context).size.width,
              child: Text(
                "❤️",
                style: TextStyle(fontSize: 46.0),
                textAlign: TextAlign.center,
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.36,
              width: MediaQuery.of(context).size.width,
              child: Text(
                "✌️",
                style: TextStyle(fontSize: 46.0),
                textAlign: TextAlign.center,
              ),
            ),

            /// This GestureDetector is here to demonstrate how the gesture event only propagate to the parent when the
            /// SlideContainer can not slide more in the direction of the drag.
            GestureDetector(
              onVerticalDragStart: (_) => print(
                  "Container cannot be slid further in that direction, this GestureDetector can take control and handle the gesture."),
              child: SlideContainer(
                slideDirection: SlideContainerDirection.vertical,
                autoSlideDuration: Duration(milliseconds: 300),
                onSlide: onSlide,
                maxSlideDistance: maxSlideDistance,
                onSlideValidated: () => HapticFeedback.mediumImpact(),
                onSlideUnvalidated: () => HapticFeedback.mediumImpact(),
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height * 0.5,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.lerp(
                            Color(0xfffddb92), Color(0xfffed6e3), position),
                        Color.lerp(
                            Color(0xffd1fdff), Color(0xff9a9ce2), position),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x90000000),
                        blurRadius: 10.0,
                        spreadRadius: 5.0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      "Slide me!",
                      style: TextStyle(fontSize: 26.0),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0.0,
              child: SlideContainer(
                controller: controller,
                slideDirection: SlideContainerDirection.horizontal,
                autoSlideDuration: Duration(milliseconds: 600),
                maxSlideDistance: maxSlideDistance,
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height * 0.5,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xfffddb92),
                        Color(0xffd1fdff),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x90000000),
                        blurRadius: 15.0,
                        spreadRadius: 10.0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      "Auto Slide",
                      style: TextStyle(fontSize: 26.0),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}
