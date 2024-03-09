import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'utils.dart';

enum Topics {
  DrawPoint,
  InAppAlert,
  InAppNotification,
  MoveMap,
  Unmanaged,
}

extension TopicsExtension on String {
  Topics toTopic() {
    final lowerCaseString = toLowerCase();
    if (lowerCaseString.contains('drawpoint')) {
      return Topics.DrawPoint;
    } else if (lowerCaseString.contains('inappalert')) {
      return Topics.InAppAlert;
    } else if (lowerCaseString.contains('inappnotification')) {
      return Topics.InAppNotification;
    } else if (lowerCaseString.contains('movemap')) {
      return Topics.MoveMap;
    } else {
      return Topics.Unmanaged;
    }
  }
}

abstract class MqttEvent {}

class DrawPointEvent extends MqttEvent {
  final String title;
  final LatLng position;
  final String topic;
  final String timestampSent;

  DrawPointEvent(this.title, this.position, this.topic, this.timestampSent);
}

class MoveMapEvent extends MqttEvent {
  final LatLng position;
  final String topic;
  final String timestampSent;

  MoveMapEvent(this.position, this.topic, this.timestampSent);
}

class InAppAlertEvent extends MqttEvent {
  final String text;
  final String topic;
  final String timestampSent;

  InAppAlertEvent(this.text, this.topic, this.timestampSent);
}

class InAppNotificationEvent extends MqttEvent {
  final String title;
  final String text;
  final String topic;
  final String timestampSent;

  InAppNotificationEvent(this.title,this.text, this.topic, this.timestampSent);
}

class MQTTManager {
  final String serverUri = getServerAddress();
  final String clientId = "Flutter-UrbanGuide";
  List<String> topicToSubscribe = [];
  late MqttServerClient client;

  MQTTManager() {
    client = MqttServerClient.withPort(serverUri, clientId, 1883);
    _connect();
  }

  void _connect() async {
    client.onConnected = () {
      for (var element in topicToSubscribe) {
        client.subscribe(element, MqttQos.exactlyOnce);
      }
      topicToSubscribe.clear();
    };

    try {
      await client.connect();
    } on Exception {
      client.disconnect();
    }
  }

  void subscribe(String topic) {
    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      client.subscribe(topic, MqttQos.exactlyOnce);
    } else {
      topicToSubscribe.add(topic);
    }
  }

  void publish(String topic, String payload) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);
    client.publishMessage(topic, MqttQos.exactlyOnce, builder.payload!);
  }

  Stream<List<MqttReceivedMessage<MqttMessage>>>? getStream() {
    return client.updates;
  }
}
