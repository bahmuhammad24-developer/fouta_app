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
- [UI Kit (Tokens/Motion/Skeleton/Images)](#ui-kit-tokensmotion-skeletonimages)
- [Getting Started](#getting-started)
- [Documentation & Logging Guidelines](#documentation--logging-guidelines)
  - [AI Collaboration](#ai-collaboration)
- [AI Collaboration & Policy](#ai-collaboration--policy)
- [Development Notes](#development-notes)
- [Media Pipeline](#media-pipeline)
- [Stories](#stories)
- [Profiles & Creator Mode](#profiles--creator-mode)
- [Monetization](#monetization)
- [Admin Analytics](#admin-analytics)
- [Notifications](#notifications)
- [Stability Utilities](#stability-utilities)

- [Composer V2 (route /composeV2)](#composer-v2-route-composev2)

- [Internationalization (i18n) scaffolding](#internationalization-i18n-scaffolding)

- [Testing](#testing)
- [CI & Status Checks](#ci--status-checks)
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
- `event_detail_screen.dart`
  - Icons: none
  - Colors: none
- `event_invite_screen.dart`
  - Icons: person
  - Colors: white
- `events_list_screen.dart`
  - Icons: add, event, filter_list, location_on_outlined, people_outline
  - Colors: grey
- `group_detail_screen.dart`
  - Icons: none
  - Colors: none
- `group_member_selection_screen.dart`
  - Icons: arrow_forward, person
  - Colors: None
- `group_setup_screen.dart`
  - Icons: group_add
  - Colors: None
- `groups_list_screen.dart`
  - Icons: add
  - Colors: none
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
- `ar_camera_screen.dart`
  - Icons: auto_awesome_outlined
  - Colors: None
- `marketplace_screen.dart`
  - Icons: storefront_outlined
  - Colors: None
- `search_screen.dart`
  - Icons: search
  - Colors: None
- `shorts_screen.dart`
  - Icons: play_arrow_outlined
  - Colors: None

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

## UI Kit (Tokens/Motion/Skeleton/Images)

The UI kit provides reusable building blocks:

- **Design Tokens** – color, spacing, radii, elevation, and text style tokens live in `lib/theme/tokens.dart`.
- **Motion System** – duration and curve tokens plus `animateOnTap` and `animatedVisibility` helpers in `lib/theme/motion.dart`.
- **Skeleton Loaders** – `Skeleton.line`, `Skeleton.rect`, and `Skeleton.avatar` with optional shimmer are in `lib/widgets/skeleton.dart`.
- **Progressive Images** – `ProgressiveImage` fades from a low-res thumbnail to the final image with error handling in `lib/widgets/progressive_image.dart`.

To adopt, import the relevant file and swap hard‑coded styles for the provided tokens or widgets.

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

## AI Collaboration & Policy
- Agents may create or switch branches other than the protected `main` branch.
- Agents may add runtime and dev dependencies when a DEP record is created and all CI checks pass.
- See [AGENTS.md](AGENTS.md) and [DEPENDENCIES.md](DEPENDENCIES.md) for full details.

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
Stories let people share ephemeral moments.

### Create
- Capture or pick a photo or video in the story camera.
- Use the overlay editor to add text, stickers, or simple shapes.
- Drag, scale, and rotate overlays; delete the selected layer from the toolbar.

### Edit
- Overlays are stored as metadata and composited at playback time.
- Videos are not re-encoded; overlays render on top during viewing.

### View
- Tap right/left to move between items.
- Long-press to pause or resume.
- Swipe down to dismiss the viewer.
- Progress bars at the top show story timing.

### Accessibility
- Avatars have 48dp tap targets and semantic labels like
  "<Author> story, unread, posted 5m ago".

### Data Saver
- Videos start muted and do not autoplay when Data Saver is enabled.

### Seen Tracking
- Items are marked seen after being visible for at least one second and cached locally for instant tray updates.

## Sharing
Repost or quote posts to add your voice, save favorites into personal collections, or share a post directly to a story with an automatic "Shared from @user" overlay.


## Profiles & Creator Mode
Profiles include display names, bios, links, location, and pronouns. Users can pin a post to the top of their profile. Enabling creator mode surfaces a dashboard with follower counts, 7-day post totals, and 7-day engagement.

## Groups
Users can create communities and join or leave them.
Firestore: `artifacts/$APP_ID/public/data/groups/{groupId}` with fields:
- `name` (`String`)
- `description` (`String?`)
- `coverUrl` (`String?`)
- `ownerId` (`String`)
- `memberIds` (`List<String>`)
- `createdAt` (`Timestamp`)

## Events
Events allow attendees to RSVP.
Firestore: `artifacts/$APP_ID/public/data/events/{eventId}` with fields:
- `title` (`String`)
- `start` (`Timestamp`)
- `end` (`Timestamp`)
- `location` (`String?`)
- `description` (`String?`)
- `coverUrl` (`String?`)
- `ownerId` (`String`)
- `attendingIds` (`List<String>`)
- `interestedIds` (`List<String>`)
- `createdAt` (`Timestamp`)
- `updatedAt` (`Timestamp`)

## Firestore Collections

- `products` – documents contain `name`, `price`, `description`, and `imageUrl` for marketplace listings.
- `purchases` – records `userId`, `productId`, and `timestamp` for digital goods transactions.

## Internationalization (i18n) scaffolding

A basic localization layer exists for English and French. To preview available strings, run the dev sandbox:

```bash
flutter run lib/devtools/localization_sandbox.dart
```

Use the buttons to switch languages.

## Testing
Run the test suite with:
```bash
flutter test
```

## CI & Status Checks

CI runs on pushes to `dev`, `feature/*`, and `fix/*` branches and on pull requests targeting `dev`.
It runs `flutter analyze`, `dart format --output=none --set-exit-if-changed .`, `flutter test --no-pub --coverage`, and `flutter build web --release`.
The coverage report is uploaded as `coverage/lcov.info`.
To re-run checks, go to Actions and select **Run workflow**.


## Environment Keys

- `FCM_SERVER_KEY` – required by Cloud Functions `onNewInteraction` to send push notifications. If unset, the function logs a TODO and exits without sending.

## Change Log

- 2025-08-13 00:00 UTC – Search, hashtag index, trending chips.
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
- 2025-08-12 20:21 UTC – Added double-tap to like posts for quicker engagement.
- 2025-08-12 20:39 UTC – Enabled users to report posts for moderation review.
- 2025-08-12 20:52 UTC – Added Shorts, Marketplace, and AR Camera stub screens accessible from the navigation drawer.
- 2025-08-15 00:00 UTC – Introduced ranking service, onboarding flow, AR effects, shorts feed, marketplace, growth and moderation tools, and Firebase Analytics integration.
- 2025-08-13 01:42 UTC – Messaging v2 (typing/read receipts/media hardening); Notifications v1 (opt-in + Function trigger).

## Contributing
- Follow the logging and documentation guidelines outlined above.
- Ensure all tests pass before submitting changes.
- Include a timestamped entry in the Change Log for every pull request.
- AI agents must document their work with timestamps and append to documentation instead of overwriting.



## Troubleshooting
- Firestore may store ID collections as lists rather than counters. Ensure fields like `likes` or `bookmarks` are read as lists before counting to avoid type cast errors.

## Data collections

- `artifacts/$APP_ID/public/data/shorts`
  - `authorId` (`String`)
  - `url` (`String`)
  - `aspectRatio` (`double`)
  - `duration` (`double` seconds)
  - `likeIds` (`List<String>`)
  - `createdAt` (`Timestamp`)
- `artifacts/$APP_ID/public/data/products`
  - `sellerId` (`String`)
  - `urls` (`List<String>`)
  - `title` (`String`)
  - `category` (`String`)
  - `price` (`double`)
  - `currency` (`String`)
  - `favoriteUserIds` (`List<String>`)
  - `createdAt` (`Timestamp`)

## Monetization
Payment flows are stubbed. The app records intents at `artifacts/$APP_ID/public/data/monetization/intents/{intentId}` with:
- `type` (`tip`\|`subscription`\|`purchase`)
- `amount` (`double`)
- `currency` (`String`)
- `targetUserId` or `productId` (`String`)
- `createdBy` (`String`)
- `createdAt` (`Timestamp`)
- `status` (`draft`\|`ready`\|`completed`\|`failed`)

**Safety:** No payment provider is wired yet; intents are placeholders pending security review.

## Admin Analytics
Daily rollups stored at `artifacts/$APP_ID/public/data/metrics/daily/{YYYY-MM-DD}` with:
- `dau` (`int`)
- `posts` (`int`)
- `shortViews` (`int`)
- `purchaseIntents` (`int`)

**Safety:** Aggregations run in scheduled functions; ensure admin-only access and monitor Firestore read costs.


## Notifications
Fouta sends notifications for follows, comments, likes, reposts, mentions, and messages. Users can manage per-type preferences from the unified settings screen.
Preferences are stored at `artifacts/$APP_ID/public/data/users/{uid}/settings/notifications` with boolean flags for each type.
In-app notifications live at `artifacts/$APP_ID/public/data/notifications/{uid}/items` and are marked read when opened.



## Stability Utilities
Reusable helpers ensure widgets and async code fail gracefully.

### Error Reporting Stub
Errors surface through `ErrorReporter.report` for centralized capture.

## Composer V2 (route /composeV2)
Experimental composer supporting drafts and scheduled posts.

### Data
- Drafts: `users/{uid}/drafts/{draftId}` with `content`, `media[]`, `updatedAt`.
- Scheduled: `users/{uid}/scheduled/{id}` with `publishAt`, `payload`.

### Testing
1. Launch the app and navigate to `/composeV2`.
2. Enter text and optionally attach media.
3. Use **Save Draft** to persist content or **Schedule** to pick a publish time.
4. Verify entries appear in the respective Firestore collections.

## Link Preview module
- Demo route: `/_dev/link-preview`
- `LinkPreviewService` fetches Open Graph data for URLs.
- Dev Cloud Function endpoint: `https://<region>-<project>.cloudfunctions.net/openGraph?url=`
  - Returns JSON `{ title, description, imageUrl, siteName }`


## Safety & Privacy v2 (route /privacy)
Route `/privacy` exposes tabs for Privacy, Safety, Muted Words, and Blocked/Muted users.

Data models are stored under `artifacts/\$APP_ID/public/data/users/{uid}/safety` documents:
- `settings` document fields:
  - `isPrivate` (`bool`)
  - `limitReplies` (`everyone`|`followers`|`none`)
  - `mutedUserIds` (`List<String>`)
  - `blockedUserIds` (`List<String>`)
- `muted_words` document field:
  - `words` (`List<String>`; lowercased)

## Troubleshooting

If constructors use non-const initializers (e.g., FirebaseAuth, service instances), remove const from widget constructors.
If a widget constructor uses services/auth in initializers, don’t construct it with const or place it inside a const list.

- Flicker often comes from recreating streams in build; cache in initState and compare maps before setState.



### Micro-interaction widgets

```dart
AnimatedLikeButton(
  isLiked: false,
  onChanged: (liked) {},
);

AnimatedBookmarkButton(
  isSaved: false,
  onChanged: (saved) {},
);

ReactionTray(
  onReactionSelected: (reaction) {
    // handle ReactionType
  },
);
```

## Navigation & List UX Utilities



## Accessibility & Motion

The app adopts focus visuals for keyboard users, clamps text scaling to a sensible maximum, and shortens or skips animations when the operating system requests reduced motion. Adjust text size or motion preferences in your device's accessibility settings to toggle these features.

## Integration Pass 1 adoption notes

- Feed, Shorts, and Marketplace now use ProgressiveImage with skeleton placeholders, SafeBuilders, and animated like/bookmark buttons.
- To revert, restore prior widgets (CachedNetworkImage, IconButton) and standard Scaffold/StreamBuilder usage.

## Hero/Transitions adoption
Feed cards and shorts now use Hero images and FoutaTransitions for smoother detail navigation.


