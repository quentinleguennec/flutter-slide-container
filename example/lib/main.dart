import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:slide_container_example/help_page.dart';
import 'package:slide_container_example/page1.dart';
import 'package:slide_container_example/page2.dart';
import 'package:slide_container_example/page3.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  static const double bottomNavigationBarHeight = 48;

  @override
  Widget build(BuildContext context) => MaterialApp(
        theme: ThemeData(splashColor: Colors.transparent),
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
  int selectedPageIndex = 0;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance
        .addPostFrameCallback((_) => Navigator.of(context).push(HelpPage()));
  }

  void onPageSelected(int index) {
    if (mounted) setState(() => selectedPageIndex = index);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: selectedPageIndex == 0
            ? Page1()
            : selectedPageIndex == 1 ? Page2() : Page3(),
        bottomNavigationBar: SizedBox(
          height: App.bottomNavigationBarHeight,
          child: BottomNavigationBar(
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Container(),
                title: Text('1'),
              ),
              BottomNavigationBarItem(
                icon: Container(),
                title: Text('2'),
              ),
              BottomNavigationBarItem(
                icon: Container(),
                title: Text('3'),
              ),
            ],
            currentIndex: selectedPageIndex,
            selectedItemColor: Colors.amber[800],
            onTap: onPageSelected,
          ),
        ),
      );
}
