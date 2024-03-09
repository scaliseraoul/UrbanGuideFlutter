import 'dart:io' show Platform;

String getServerAddress() {
  if (Platform.isAndroid) {
    return '10.0.2.2';
  } else if (Platform.isIOS) {
    return 'localhost';
  } else {
    throw UnsupportedError("This platform is not supported");
  }
}

String getBaseTopic() {
  if (Platform.isAndroid) {
    return 'AndroidFlutterMapbox';
  } else if (Platform.isIOS) {
    return 'iOSFlutterMapbox';
  } else {
    throw UnsupportedError("This platform is not supported");
  }
}

String getOsString() {
  if (Platform.isAndroid) {
    return 'Android';
  } else if (Platform.isIOS) {
    return 'iOS';
  } else {
    throw UnsupportedError("This platform is not supported");
  }
}