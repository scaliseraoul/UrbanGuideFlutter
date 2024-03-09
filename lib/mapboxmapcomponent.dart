import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'utils.dart';
import 'mqtt_manager.dart';

class MapboxMapComponent extends StatefulWidget {
  const MapboxMapComponent(
      {super.key, required this.mqttManager, required this.eventStream});

  final MQTTManager mqttManager;
  final Stream<MqttEvent> eventStream;
  static final String baseTopic = "${getOsString()}FlutterMapbox";

  @override
  State<MapboxMapComponent> createState() => _MapboxMapComponentState();
}

class _MapboxMapComponentState extends State<MapboxMapComponent> {
  late MapboxMapController mapController;
  final Stopwatch moveMapStopwatch = Stopwatch();
  String timestampSent = "";
  bool registerMotion = false;

  void _onMapCreated(MapboxMapController controller) {
    mapController = controller;
    MQTTManager mqttManager = widget.mqttManager;
    String baseTopic = MapboxMapComponent.baseTopic;
    mqttManager.subscribe("$baseTopic${Topics.DrawPoint.name}Receive");
    mqttManager.subscribe("$baseTopic${Topics.MoveMap.name}Receive");
    Stream<MqttEvent> eventStream = widget.eventStream;
    eventStream.listen((event) {
      if (event is DrawPointEvent) {
        addMarkers(event);
      } else if (event is MoveMapEvent) {
        moveMap(event);
      }
    });
  }

  void _onStyleLoaded() {
    addIcon();
  }

  Future<void> addIcon() async {
    final ByteData byteData =
        await rootBundle.load("images/mapbox_marker_icon_20px_blue.png");
    final Uint8List list = byteData.buffer.asUint8List();
    mapController.addImage("blue-marker", list);
  }

  void addMarkers(DrawPointEvent event) {
    Stopwatch addMarkerStopwatch = Stopwatch()..start();
    mapController.addSymbol(SymbolOptions(
      geometry: event.position,
      textField: event.title,
      iconImage: "blue-marker",
      iconSize: 4.0,
    ));
    final elapsedTime = addMarkerStopwatch.elapsedMicroseconds * 1000;
    MQTTManager mqttManager = widget.mqttManager;
    final mqttPayload =
        "${event.timestampSent},${getOsString()},Flutter,MapBox,${Topics.DrawPoint.name},0,0,$elapsedTime";

    mqttManager.publish(
        "${MapboxMapComponent.baseTopic}${Topics.DrawPoint.name}Complete",
        mqttPayload);
    addMarkerStopwatch.reset();
  }

  void moveMap(MoveMapEvent event) {
    timestampSent = event.timestampSent;
    registerMotion = true;
    moveMapStopwatch.start();
    mapController.moveCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        target: event.position,
        zoom: 15.0,
      ),
    ));
  }

  void onCameraIdle() {
    moveMapStopwatch.stop();

    if (!registerMotion) {
      return;
    }

    registerMotion = false;

    MQTTManager mqttManager = widget.mqttManager;
    final elapsedTime = moveMapStopwatch.elapsedMicroseconds * 1000;
    final mqttPayload =
        "$timestampSent,${getOsString()},Flutter,MapBox,${Topics.MoveMap.name},0,0,$elapsedTime";

    mqttManager.publish(
        "${MapboxMapComponent.baseTopic}${Topics.MoveMap.name}Complete",
        mqttPayload);
    moveMapStopwatch.reset();
  }

  @override
  Widget build(BuildContext context) {
    return MapboxMap(
      onMapCreated: _onMapCreated,
      onStyleLoadedCallback: _onStyleLoaded,
      onCameraIdle: onCameraIdle,
      accessToken: const String.fromEnvironment("ACCESS_TOKEN"),
      initialCameraPosition: const CameraPosition(
        target: LatLng(44.646469, 10.925139),
        zoom: 15.0,
      ),
      compassEnabled: false,
      myLocationEnabled: false,
      myLocationTrackingMode: MyLocationTrackingMode.None,
    );
  }
}
