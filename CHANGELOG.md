## 1.1.1 - 2019-10-09

* Added option to disable auto-slide, allowing the container to stay where it as been dragged when the gesture end, instead of snapping to the start position or to the full extent.

## 1.1.0 - 2019-09-18

* **Breaking change** Fixed naming issue with new Flutter version (1.9.0 and above). Use this version of the plugin when you upgrade Flutter.

## 1.0.7 - 2018-11-29

* Added the SlideContainerController to allow a manual force slide in a given direction.
* Updated example app to showcase the new SlideContainerController.

## 1.0.6 - 2018-10-25

* Fixed Flutter analysis warnings.

## 1.0.5 - 2018-10-25

* Fixed Flutter analysis warnings. 

## 1.0.4 - 2018-10-25

* Added onSlideValidated and onSlideUnvalidated callbacks.

## 1.0.3 - 2018-10-10

* Improved logic to reduce nested GestureDetector conflicts. Now if the container as been slid to
its max extent in one direction, trying to slid it more in this direction will not count as a gesture,
thus allowing other GestureDetectors to get and handle the event.

## 1.0.2 - 2018-10-09

* Updated README.

## 1.0.1 - 2018-10-06

* Added support for horizontal sliding.
* **Breaking change**
    * Renamed class `VerticalSlideContainer` to `SlideContainer`
    * Renamed enum `VerticalSlideContainerDirection` to `SlideContainerDirection` and changed its values.

## 1.0.0 - 2018-10-05

* Initial release.
