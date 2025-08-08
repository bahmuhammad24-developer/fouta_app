# fouta_app

## Table of Contents
- [Overview](#overview)
- [App Structure](#app-structure)
  - [Directory Structure](#directory-structure)
  - [Screens](#screens)
  - [Widgets](#widgets)
  - [Theme](#theme)
- [Getting Started](#getting-started)
- [Documentation & Logging Guidelines](#documentation--logging-guidelines)
  - [AI Collaboration](#ai-collaboration)
- [Development Notes](#development-notes)
- [Testing](#testing)
- [Change Log](#change-log)
- [Contributing](#contributing)

## Overview
Fouta App is a cross-platform Flutter application that integrates Firebase services and supports story creation with camera and microphone features.

## App Structure

### Directory Structure

- `lib/`
  - `screens/` – UI screens
  - `widgets/` – Reusable components
  - `models/` – Data models
  - `services/` – Backend services
  - `theme/` – App theming
  - `utils/` – Utilities

### Screens

- `account_settings_screen.dart`
  - Icons: None
  - Colors: red
- `add_members_screen.dart`
  - Icons: person
  - Colors: None
- `auth_screen.dart`
  - Icons: email_outlined, location_city_outlined, lock_outlined, person_outline, phone_outlined
  - Colors: green, grey
- `chat_details_screen.dart`
  - Icons: add, block, person_add
  - Colors: black, red, white
- `chat_screen.dart`
  - Icons: close, error, image, info_outline, mic, play_circle_fill, reply, send, videocam
  - Colors: black, black54, grey, red, white, white54
- `create_event_screen.dart`
  - Icons: calendar_today, camera_alt, person_add, save
  - Colors: grey
- `create_post_screen.dart`
  - Icons: broken_image, clear, image, play_circle_fill, videocam
  - Colors: black, black12, green, grey, red, white
- `data_saver_screen.dart`
  - Icons: data_saver_on
  - Colors: grey
- `edit_event_screen.dart`
  - Icons: calendar_today, camera_alt, save
  - Colors: grey
- `event_details_screen.dart`
  - Icons: access_time, calendar_today, check_circle_outline, edit, event, location_on, person, send
  - Colors: grey, white
- `event_invite_screen.dart`
  - Icons: person
  - Colors: white
- `events_list_screen.dart`
  - Icons: add, event, filter_list, location_on_outlined, people_outline
  - Colors: grey
- `group_member_selection_screen.dart`
  - Icons: arrow_forward, person
  - Colors: None
- `group_setup_screen.dart`
  - Icons: group_add
  - Colors: None
- `home_screen.dart`
  - Icons: add_circle_outline, archive_outlined, chat_bubble_outline, event_outlined, home_outlined, info_outline, logout, menu, message, notifications_outlined, people_outlined, person, person_outlined, search, settings_outlined, volume_mute_outlined, wifi_off
  - Colors: blue, green, grey, white
- `new_chat_screen.dart`
  - Icons: group_add, person
  - Colors: None
- `notifications_screen.dart`
  - Icons: comment, favorite, notifications, person_add
  - Colors: blue, green, grey, red, white
- `post_detail_screen.dart`
  - Icons: None
  - Colors: red
- `privacy_settings_screen.dart`
  - Icons: None
  - Colors: red
- `profile_screen.dart`
  - Icons: edit, error, grid_on, person, photo_library, play_circle_filled
  - Colors: green, grey, white
- `story_camera_screen.dart`
  - Icons: cameraswitch, flash_off, photo_library
  - Colors: black, white
- `story_creation_screen.dart`
  - Icons: send
  - Colors: black, white
- `story_viewer_screen.dart`
  - Icons: close, delete, error, person
  - Colors: black, white, white38
- `unified_settings_screen.dart`
  - Icons: dark_mode_outlined, data_saver_on_outlined, delete_forever_outlined, info_outline, lock_outline, person_outline, privacy_tip_outlined
  - Colors: green, red, white

### Widgets

- `chat_audio_player.dart`
  - Icons: play_circle
  - Colors: black12, white10
- `chat_video_player.dart`
  - Icons: None
  - Colors: black, white, white70
- `fouta_card.dart`
  - Icons: None
  - Colors: black
- `full_screen_image_viewer.dart`
  - Icons: None
  - Colors: black, white
- `full_screen_video_player.dart`
  - Icons: close
  - Colors: black, white
- `media_viewer.dart`
  - Icons: broken_image, play_circle_fill
  - Colors: black, white, white54
- `post_card_widget.dart`
  - Icons: broken_image, comment, favorite_border, person, play_circle_fill, repeat, send, share
  - Colors: black, black54, grey, white, white70
- `share_post_dialog.dart`
  - Icons: broken_image, play_circle_fill
  - Colors: black, grey, white
- `stories_tray.dart`
  - Icons: add_circle, person
  - Colors: grey, white
- `video_player_widget.dart`
  - Icons: fullscreen, play_arrow, volume_up
  - Colors: black, white, white70

### Theme

- `fouta_theme_diaspora.dart`
  - Light: primary `#3C7548`, secondary `#F4D87B`, background `#F7F5EF`, surface `#FFFFFF`, error `#D9534F`
  - Dark: primary `#2A4930`, secondary `#B38A40`, background `#1F2620`, surface `#2D362D`, error `#D9534F`, text `#E5E5E5`

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
- Configured iOS permission macros to enable camera and microphone access and avoid crashes when creating stories on iOS.

For help getting started with Flutter development, view the [online documentation](https://docs.flutter.dev/), which offers tutorials, samples, guidance on mobile development, and a full API reference.

## Documentation & Logging Guidelines
- Include the current date and time in every log message (e.g., `2025-08-08 02:05 UTC`).
- Record every change to the app in the [Change Log](#change-log) with a timestamp.
- Update this README and other documentation whenever features or behaviors change.

### AI Collaboration
- AI agents must document their work, including context, decisions, and timestamps.
- Append updates to existing documentation and logs rather than overwriting previous entries.

## Development Notes

### iOS Build Setup & Firebase Integration
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

## Testing
Run the test suite with:
```bash
flutter test
```

## Change Log
 - 2025-08-08 03:09 UTC – Increased video upload limit to 500 MB for posts and chats and expanded video cache capacity.
- 2025-08-08 02:36 UTC – Registered device tokens and added Cloud Function to send push notifications for new chat messages.
- 2025-08-08 02:21 UTC – Added AI collaboration guidelines requiring agents to document their work.
- 2025-08-08 02:15 UTC – Expanded README with a hierarchical app structure including all icons and color choices.
- 2025-08-08 02:05 UTC – Added documentation and logging guidelines to the README.
- 2025-08-07 22:02 UTC – Updated platform configuration and dependencies to support camera and microphone permissions.
- 2025-08-07 21:54 UTC – Handled camera and microphone permissions in the story camera screen to prevent a crash when creating stories.

## Contributing
- Follow the logging and documentation guidelines outlined above.
- Ensure all tests pass before submitting changes.
- Include a timestamped entry in the Change Log for every pull request.
- AI agents must document their work with timestamps and append to documentation instead of overwriting.


