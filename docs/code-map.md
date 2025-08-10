# Code Map


## Navigation
- **Entry point:** `main.dart` initializes Firebase, loads `ThemeController`, and injects `ConnectivityProvider`, `VideoPlayerManager`, and `ThemeController` via `MultiProvider` before launching `MyApp` which sets `SplashScreen` as the home widget【F:lib/main.dart†L24-L68】
- **Splash flow:** `SplashScreen` animates then decides between `AuthWrapper` and notification permission screen【F:lib/screens/splash_screen.dart†L21-L33】
- **Auth routing:** `AuthWrapper` listens to `FirebaseAuth` state and pushes either `HomeScreen` or `AuthScreen`【F:lib/main.dart†L74-L99】
- **Home routing:** `HomeScreen` hosts a bottom `NavigationBar` and a matching `IndexedStack` of nested `Navigator`s for Feed, Chat, Events, People, and Profile tabs【F:lib/screens/home_screen.dart†L176-L205】【F:lib/screens/home_screen.dart†L260-L275】

## Screens
- account_settings_screen.dart
- add_members_screen.dart
- auth_screen.dart
- chat_details_screen.dart
- chat_screen.dart
- create_event_screen.dart
- create_post_screen.dart
- data_saver_screen.dart
- edit_event_screen.dart
- event_details_screen.dart
- event_invite_screen.dart
- events_list_screen.dart
- group_member_selection_screen.dart
- group_setup_screen.dart
- home_screen.dart (also defines `FeedTab`, `ChatsTab`, `PeopleTab`)
- media_viewer.dart
- new_chat_screen.dart
- notification_permission_screen.dart
- notifications_screen.dart
- post_detail_screen.dart
- privacy_settings_screen.dart
- profile_screen.dart
- splash_screen.dart
- story_camera_screen.dart
- story_creation_screen.dart *(unused)*
- story_viewer_screen.dart *(export wrapper)*
- stories/story_viewer_screen.dart *(unused)*
- unified_settings_screen.dart

## Widgets
- chat/audio_message_bubble.dart
- chat/audio_recorder.dart
- chat/chat_composer.dart
- chat/message_bubble.dart
- chat/message_list.dart
- chat/typing_indicator.dart
- chat_audio_player.dart *(export wrapper)*
- chat_message_bubble.dart *(export wrapper)*
- chat_video_player.dart
- fouta_button.dart
- fouta_card.dart
- full_screen_image_viewer.dart
- full_screen_video_player.dart
- media/post_media.dart
- media/video_player_view.dart
- post_card_widget.dart
- share_post_dialog.dart
- skeletons/events_skeleton.dart
- skeletons/feed_skeleton.dart
- skeletons/notifications_skeleton.dart
- skeletons/profile_skeleton.dart
- stories/stories_tray.dart
- stories_tray.dart *(export wrapper)*
- video_player_widget.dart

## Services & Providers
- connectivity_provider.dart *(ChangeNotifier)*
- media_prefetcher.dart
- push_notification_service.dart
- stories_service.dart *(tracks seen stories; TODO to persist)*【F:lib/services/stories_service.dart†L5-L15】
- video_cache_service.dart
- video_player_manager.dart *(ChangeNotifier)*
- theme/theme_controller.dart *(ChangeNotifier)*

## Models
- media_item.dart
- message.dart
- post_model.dart
- story.dart *(defines `Story` & `StoryItem`)*
- story_model.dart *(alternative `Story`/`StorySlide`)*

## Routes & Feature Wiring
- Bottom navigation index → tab mapping handled in `HomeScreen` via `_buildOffstageNavigator`:
  - 0 → `FeedTab`
  - 1 → `ChatsTab`
  - 2 → `EventsListScreen`
  - 3 → `PeopleTab`
  - 4 → `ProfileScreen`
- `StoriesTray` displayed in feed; tapping add opens `StoryCameraScreen` then `CreatePostScreen` with `isStory` flag【F:lib/screens/home_screen.dart†L720-L752】【F:lib/screens/home_screen.dart†L740-L748】

## Story Feature Files
- **Camera:** `story_camera_screen.dart`
- **Composer:** `story_creation_screen.dart` *(unused)*
- **Viewer:** `stories/story_viewer_screen.dart` *(unused, exported by `story_viewer_screen.dart`)*
- **Tray Widget:** `widgets/stories/stories_tray.dart`
- **Client Service:** `services/stories_service.dart`
- **Models:** `models/story.dart`, `models/story_model.dart`
- **Firestore path:** `utils/firestore_paths.dart` → `stories()`【F:lib/utils/firestore_paths.dart†L17-L18】
- **Storage path:** `story_creation_screen.dart` writes to `stories/{uid}/{timestamp}` in Firebase Storage【F:lib/screens/story_creation_screen.dart†L106-L122】
- **Security rules:** `firebase/storage.rules` allow read/write for `/stories` and legacy `/stories_media` paths【F:firebase/storage.rules†L39-L47】

## Theme
- `main.dart` applies `AppTheme.light()`/`dark()` and binds `ThemeController.themeMode`【F:lib/main.dart†L55-L68】
- Users can override theme mode via `UnifiedSettingsScreen` options (system/light/dark)【F:lib/screens/unified_settings_screen.dart†L222-L249】

## TODOs & Dead Code
- TODOs in chat message bubble, chat composer, and stories service【F:lib/widgets/chat/message_bubble.dart†L40-L45】【F:lib/widgets/chat/chat_composer.dart†L40-L64】【F:lib/services/stories_service.dart†L11-L15】
- Unused: `story_creation_screen.dart`, `stories/story_viewer_screen.dart`, `compat/theme_compat.dart`

## Build & Firebase Config
- No Android/iOS product flavors; only `debug` and `release` build types in `android/app/build.gradle.kts`【F:android/app/build.gradle.kts†L69-L79】
- Firebase options generated in `lib/firebase_options.dart` with web, Android, and iOS configs【F:lib/firebase_options.dart†L49-L73】
- Project-level `firebase.json` ties Firestore and Storage rules to files in `/firebase` directory.

## Duplicate Classes & Overlapping Rules
- `Story` class defined in both `models/story.dart` and `models/story_model.dart` with differing shapes【F:lib/models/story.dart†L4-L27】【F:lib/models/story_model.dart†L1-L24】
- Export wrappers duplicate file names for `story_viewer_screen.dart`, `stories_tray.dart`, `chat_message_bubble.dart`
- Storage rules include overlapping story paths `/stories` and legacy `/stories_media`【F:firebase/storage.rules†L39-L47】


## Added
- lib/utils/log_buffer.dart
- lib/utils/bug_reporter.dart
- lib/screens/report_bug_screen.dart
- lib/widgets/report_bug_button.dart

## Updated
- lib/screens/unified_settings_screen.dart (settings entry)
- lib/screens/media_viewer.dart (overflow entry)
- firebase/firestore.rules (bug_reports match)
- firebase/storage.rules (bug_reports attachments)

