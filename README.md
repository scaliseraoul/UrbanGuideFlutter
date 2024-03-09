# urban_guide_flutter

Urban Guide Flutter project.

## Getting Started

This app needs Flutter Mapbox Maps plugin
https://pub.dev/packages/mapbox_maps_flutter 

Extract from the guide:

### Secret token
To access platform SDKs you will need to create a secret access token with the Downloads:Read scope and then:

1. to download the Android SDK add the token configuration to ~/.gradle/gradle.properties :
SDK_REGISTRY_TOKEN=YOUR_SECRET_MAPBOX_ACCESS_TOKEN

2. to download the iOS SDK add the token configuration to ~/.netrc :
machine api.mapbox.com
login mapbox
password YOUR_SECRET_MAPBOX_ACCESS_TOKEN

### Public token
flutter run --dart-define PUBLIC_ACCESS_TOKEN=...

You can set this in the run configuration on Android Studio:
1. click on main.dart next to run button
2. edit configuration
3. add " --dart-define ACCESS_TOKEN=pk..." in Additional run args
