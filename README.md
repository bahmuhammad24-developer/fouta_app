# fouta_app

## Table of Contents
- [Overview](#overview)
- [Vision](#vision)
- [Architecture & Competitive Alignment](#architecture--competitive-alignment)
- [App Structure](#app-structure)
  - [Directory Structure](#directory-structure)
  - [Screens](#screens)
  - [Widgets](#widgets)
  - [Theme](#theme)
- [Getting Started](#getting-started)
- [Documentation & Logging Guidelines](#documentation--logging-guidelines)
  - [AI Collaboration](#ai-collaboration)
- [Development Notes](#development-notes)
- [Media Pipeline](#media-pipeline)
- [Stories](#stories)
- [Testing](#testing)
- [Change Log](#change-log)
- [Contributing](#contributing)

## Overview
Fouta App is a cross-platform Flutter application that integrates Firebase services and supports story creation with camera and microphone features. It is tailored for the global majority and commits to open dialogue on issues affecting vulnerable communities.

## Vision
Fouta centers the global majority. The platform avoids suppressing discussions on topics that impact vulnerable communities while equipping users with tools to report abuse and curate their experience. This balance aims to foster open, respectful conversations.

See [docs/vision.md](docs/vision.md) for the broader roadmap.

## Architecture & Competitive Alignment
Dedicated feature modules keep the project competitive with larger platforms. The roadmap for discovery, moderation, growth, analytics, and monetization lives in [docs/architecture.md](docs/architecture.md).

## Chat Pro Features
- Composer supports text and attachments
- Message bubbles expose basic status, replies, reactions placeholders
- Audio messages behind feature flag `kChatAudioEnabled`
- Offline queue and retry logic planned

## App Structure

### Directory Structure

- `lib/`
  - `screens/` – UI screens
  - `widgets/` – Reusable components
  - `models/` – Data models
  - `services/` – Backend services
  - `theme/` – App theming
  - `utils/` – Utilities
  - `features/`
    - `discovery/`
    - `moderation/`
    - `growth/`
    - `analytics/`
    - `monetization/`

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
- `bookmarks_screen.dart`
  - Icons: bookmark
  - Colors: None
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
  - Icons: archive_outlined, chat_bubble_outline, event_outlined, home_outlined, info_outline, logout, menu, message, notifications_outlined, people_outlined, person, person_outlined, search, settings_outlined, volume_mute_outlined, wifi_off
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
  - `features/stories/camera/story_camera_screen.dart`
  - Icons: cameraswitch, flash_off, photo_library
  - Colors: black, white
  - `features/stories/composer/create_story_screen.dart`
  - Icons: send
  - Colors: black, white
  - `features/stories/viewer/story_viewer_screen.dart`
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
  - `fullscreen_media_viewer.dart`
    - Icons: pause_circle, play_circle
    - Colors: black, white
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
- Ensured background push notifications work by marking the Firebase Messaging background handler as an entry point and logging when notifications open the app.

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


## Media Pipeline
Uploads are processed server-side to improve delivery speed and quality. Videos exceeding `kMaxVideoBytes` (~500 MB) are rejected before upload to keep processing manageable. A Cloud Function listens for new files in Firebase Storage and:

- Resizes images to thumb (128w), preview (480w), and full (~1080w) using **sharp**.
- Captures a poster frame for videos and generates the same sizes.
- Computes a BlurHash for each media item.
- Writes the resulting URLs, dimensions, and blurhash to `artifacts/fouta-app/public/data/media/{docId}` in Firestore.

When creating a post, the app waits for this metadata and then stores the progressive URLs. Feeds display the blurhash first, then the preview image, and finally the full version.

To attach captions to a video, upload a WebVTT file to Storage and set its download URL in the media document's `captionUrl` field. The app will include this subtitle track when available.

## Stories

### Gestures
- Tap right/left to move between items.
- Long-press to pause or resume.
- Swipe down to dismiss the viewer.

### Accessibility
- Avatars have 48dp tap targets and semantic labels like
  "<Author> story, unread, posted 5m ago".

### Data Saver
- Videos start muted and do not autoplay when Data Saver is enabled.

### Seen Tracking
- Items are marked seen after being visible for at least one second and cached locally for instant tray updates.


## Testing
Run the test suite with:
```bash
flutter test
```

## Change Log

- 2025-08-09 01:30 UTC – Implemented server-side media pipeline generating progressive images, video posters, and blurhash placeholders.
- 2025-08-09 01:39 UTC – Introduced new story models, tray, viewer scaffolding, and documented gestures and accessibility.
- 2025-08-09 01:39 UTC – Introduced chat composer, message models, and placeholders for advanced chat features.
- 2025-08-08 23:10 UTC – Aligned story timestamps with the app-wide relative format for consistency.
- 2025-08-08 11:50 UTC – Adjusted bottom navigation bar height to account for device padding and prevent overflow errors.
- 2025-08-08 06:18 UTC – Marked Firebase Messaging background handler as an entry point and logged notification open events to enable push notifications when the app is closed.
- 2025-08-08 02:36 UTC – Registered device tokens and added Cloud Function to send push notifications for new chat messages.
- 2025-08-08 02:21 UTC – Added AI collaboration guidelines requiring agents to document their work.
- 2025-08-08 02:15 UTC – Expanded README with a hierarchical app structure including all icons and color choices.
- 2025-08-08 02:05 UTC – Added documentation and logging guidelines to the README.
- 2025-08-07 22:02 UTC – Updated platform configuration and dependencies to support camera and microphone permissions.
- 2025-08-07 21:54 UTC – Handled camera and microphone permissions in the story camera screen to prevent a crash when creating stories.
- 2025-08-09 00:43 UTC – Adopted Material 3 design system with tokenized theme and removed hard-coded colors.
- 2025-08-13 00:00 UTC – Removed video size constraints by aligning video uploads with image handling.
- 2025-08-12 15:07 UTC – Clarified 500 MB video upload limit with snackbar message and documentation.
- 2025-08-12 16:31 UTC – Centralized video upload limit in `kMaxVideoBytes` and referenced it in docs.
- 2025-08-14 00:00 UTC – Documented global majority vision and roadmap.
- 2025-08-12 19:46 UTC – Scaffolded discovery, moderation, growth, analytics, and monetization modules and documented competitive architecture.
- 2025-08-12 20:09 UTC – Added post bookmarking with a dedicated screen for viewing saved posts.

## Contributing
- Follow the logging and documentation guidelines outlined above.
- Ensure all tests pass before submitting changes.
- Include a timestamped entry in the Change Log for every pull request.
- AI agents must document their work with timestamps and append to documentation instead of overwriting.


