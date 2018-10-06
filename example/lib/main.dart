import 'package:flutter/material.dart';
import 'package:slide_container/slide_container.dart';

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
  double position = 0.0;

  double get maxSlideDistance => MediaQuery.of(context).size.height * 0.4;

  void onSlide(double position) {
    setState(() => this.position = position);
  }

  @override
  Widget build(BuildContext context) => new Stack(
        children: <Widget>[
          Positioned(
            top: MediaQuery.of(context).size.height * 0.20,
            width: MediaQuery.of(context).size.width,
            child: Text(
              "❤️",
              style: TextStyle(fontSize: 46.0),
              textAlign: TextAlign.center,
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.20,
            width: MediaQuery.of(context).size.width,
            child: Text(
              "✌️",
              style: TextStyle(fontSize: 46.0),
              textAlign: TextAlign.center,
            ),
          ),
          VerticalSlideContainer(
            slideDirection: VerticalSlideContainerDirection.bidirectional,
            onSlide: onSlide,
            maxSlideDistance: maxSlideDistance,
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(Color(0xfffddb92), Color(0xfffed6e3), position),
                    Color.lerp(Color(0xffd1fdff), Color(0xff9a9ce2), position),
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
                  "Slide me!",
                  style: TextStyle(fontSize: 26.0),
                ),
              ),
            ),
          ),
        ],
      );
}
