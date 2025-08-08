# fouta_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


## Recent Changes

- Handle camera and microphone permissions in the story camera screen to prevent a crash when creating stories.
- Updated platform configuration and dependencies to support these permissions.

## iOS Build Setup & Firebase Integration

- **Regenerating the iOS project:** The previous `ios/` directory was removed and `flutter create .` was run to regenerate a clean iOS project, eliminating stale Swift Package references that caused duplicate module errors.
- **Podfile setup:** The Podfile loads the helper script from the Flutter SDK, uses static frameworks and modular headers, and includes a safe `post_install` hook:

  ```ruby
  platform :ios, '12.0'
  load File.join('/Users/Momo/Developer/flutter', 'packages', 'flutter_tools', 'bin', 'podhelper.rb')

  use_frameworks! :linkage => :static
  use_modular_headers!

  post_install do |installer|
    if defined?(flutter_post_install)
      flutter_post_install(installer)
    else
      installer.pods_project.targets.each do |target|
        flutter_additional_ios_build_settings(target)
        target.build_configurations.each do |config|
          config.build_settings['HEADER_SEARCH_PATHS'] ||= ['$(inherited)']
          config.build_settings['HEADER_SEARCH_PATHS'] << '$(PODS_ROOT)/gRPC-C++/include'
          config.build_settings['HEADER_SEARCH_PATHS'] << '$(PODS_ROOT)/gRPC-Core/include'
        end
      end
    end
  end
  ```

- **Avoiding Swift Package Manager for Firebase:** A "redefinition of module Firebase" error occurred when `firebase-ios-sdk` was added via Swift Package Manager. All Swift packages were removed; add Firebase only through CocoaPods.
- **Running builds:** After changing any Dart dependencies run:

  ```bash
  flutter clean
  flutter pub get
  cd ios
  pod install
  ```

  Always open `ios/Runner.xcworkspace` (not `Runner.xcodeproj`) in Xcode. Select *Any iOS Device* or a physical device to enable archiving.
- **gRPC header search paths:** The Podfile adds `$(PODS_ROOT)/gRPC-C++/include` and `$(PODS_ROOT)/gRPC-Core/include` to the header search paths to fix missing gRPC headers.
- **Bundle ID and Firebase plist:** The project uses bundle ID `com.example.foutaApp`. If you register a new Firebase app, replace `ios/Runner/GoogleService-Info.plist` with the file downloaded from Firebase.
- **Record plugin:** The `record` plugin was upgraded to 6.x to resolve Swift compilation errors. Future plugin upgrades should follow the clean sequence above.


