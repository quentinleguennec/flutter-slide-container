import 'package:flutter/material.dart';
import 'package:slide_container/slide_container.dart';
import 'package:slide_container/slide_container_controller.dart';

/// This example shows a limitation in Flutter preventing hit test detection if the child gesture detector is out
/// of it's parent bounds as described here: https://github.com/flutter/flutter/issues/27587
///
/// The current solution is to make sure the [SlideContainer] always stays in its parent bounds, even when translated
/// to it's [SlideContainer.maxSlideDistance].
/// Of course, if the [SlideContainer] is translated off screen or under something that completely cover it this issue
/// will not be noticeable, and the size of the parent doesn't matter (like in [Page1]).
///
/// The green area is the parent bounds. On the bottom [SlideContainer] you can see that it will not respond if you
/// slide it up and then try to slide it down by dragging on the top part of the [SlideContainer] (the part that is out
/// of the parent bounds).
class Page2 extends StatefulWidget {
  @override
  _State createState() => _State();
}

class _State extends State<Page2> {
  final SlideContainerController controller = SlideContainerController();

  double get maxSlideDistance => MediaQuery.of(context).size.height * 0.1;

  @override
  Widget build(BuildContext context) => Container(
        constraints: BoxConstraints.expand(),
        child: Stack(
          children: <Widget>[
            Container(
              alignment: Alignment.center,
              height: MediaQuery.of(context).size.height * 0.25 +
                  maxSlideDistance * 2,
              color: Colors.green.withOpacity(0.3),
              child: SlideContainer(
                slideDirection: SlideContainerDirection.vertical,
                maxSlideDistance: maxSlideDistance,
                child: Container(
                  alignment: Alignment.center,
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height * 0.25,
                  decoration: BoxDecoration(
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
                  ),
                  child: Text(
                    "Parent big enough",
                    style: TextStyle(fontSize: 26.0),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.1,
              child: Container(
                alignment: Alignment.center,
                height: MediaQuery.of(context).size.height * 0.25,
                color: Colors.green.withOpacity(0.3),
                child: SlideContainer(
                  slideDirection: SlideContainerDirection.vertical,
                  maxSlideDistance: maxSlideDistance,
                  child: Container(
                    alignment: Alignment.center,
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height * 0.25,
                    decoration: BoxDecoration(
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
                    ),
                    child: Text(
                      "Parent NOT big enough",
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
