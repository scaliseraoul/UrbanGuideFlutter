import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'mapboxmapcomponent.dart';
import 'notification_service.dart';
import 'utils.dart';
import 'mqtt_manager.dart';
import 'package:mqtt_client/mqtt_client.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  NotificationService.initialize();
  runApp(const UrbanGuide());
}

class UrbanGuide extends StatefulWidget {
  const UrbanGuide({super.key});

  @override
  _UrbanGuideState createState() => _UrbanGuideState();
}

class _UrbanGuideState extends State<UrbanGuide> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();
  late MQTTManager _mqttManager;
  final StreamController<MqttEvent> _eventController =
      StreamController<MqttEvent>.broadcast();

  @override
  void initState() {
    super.initState();
    //NOTIFICATION
    //MQTT
    _mqttManager = MQTTManager();
    _mqttManager
        .subscribe("${getOsString()}Flutter${Topics.InAppAlert.name}Receive");
    _mqttManager.subscribe(
        "${getOsString()}Flutter${Topics.InAppNotification.name}Receive");
    _mqttManager.getStream()?.listen((c) {
      final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
      final payload = json.decode(
          MqttPublishPayload.bytesToStringAsString(message.payload.message));
      final topicEnum = c[0].topic.toTopic();

      switch (topicEnum) {
        case Topics.MoveMap:
          double lat = payload["lat"];
          double lang = payload["lang"];
          LatLng position = LatLng(lat, lang);
          final event =
              MoveMapEvent(position, Topics.MoveMap.name, payload["timestamp"]);
          _eventController.add(event);
          break;
        case Topics.DrawPoint:
          double lat = payload["lat"];
          double lang = payload["lang"];
          LatLng position = LatLng(lat, lang);
          final event = DrawPointEvent(payload["title"], position,
              Topics.DrawPoint.name, payload["timestamp"]);
          _eventController.add(event);
          break;
        case Topics.InAppNotification:
          final event = InAppNotificationEvent(
              payload["title"],
              payload["text"],
              Topics.InAppNotification.name,
              payload["timestamp"]);
          displayAndMeasureInAppNotification(event);
          break;
        case Topics.InAppAlert:
          final event = InAppAlertEvent(
              payload["text"], Topics.InAppAlert.name, payload["timestamp"]);
          displayAndMeasureInAppAlert(event);
          break;
        case Topics.Unmanaged:
        default:
          break;
      }
    });
  }

  void displayAndMeasureInAppAlert(InAppAlertEvent event) {
    final inAppAlertStopwatch = Stopwatch()..start();

    _scaffoldKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(event.text),
        duration: const Duration(seconds: 1),
        onVisible: () {
          inAppAlertStopwatch.stop();
          final elapsedTime = inAppAlertStopwatch.elapsedMilliseconds * 1000;
          final mqttPayload =
              "${event.timestampSent},${getOsString()},Flutter,-,${Topics.InAppAlert.name},0,0,$elapsedTime";
          _mqttManager.publish(
              "${getOsString()}Flutter${Topics.InAppAlert.name}Complete",
              mqttPayload);
          inAppAlertStopwatch.reset();
        },
      ),
    );
  }

  void displayAndMeasureInAppNotification(InAppNotificationEvent event) {
    final inAppNotificationStopwatch = Stopwatch()..start();
    NotificationService.showNotification(event.title, event.text)
        .whenComplete(() {
      inAppNotificationStopwatch.stop();
      final elapsedTime = inAppNotificationStopwatch.elapsedMilliseconds * 1000;
      final mqttPayload =
          "${event.timestampSent},${getOsString()},Flutter,-,${Topics.InAppNotification.name},0,0,$elapsedTime";
      _mqttManager.publish(
          "${getOsString()}Flutter${Topics.InAppNotification.name}Complete",
          mqttPayload);
      inAppNotificationStopwatch.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: ScaffoldMessenger(
          key: _scaffoldKey,
          child: Scaffold(
            body: Center(
              child: MapboxMapComponent(
                mqttManager: _mqttManager,
                eventStream: _eventController.stream,
              ),
            ),
          )),
    );
  }
}
