# Events Taxonomy

| Event | Use Case | Trigger | Recommended Props |
| ----- | -------- | ------- | ----------------- |
| `video_complete` | UC-01 | `next_up_rail` | `video_duration`, `position_in_session` |
| `next_up_click` | UC-01 | `next_up_rail` | `recommended_id`, `position_in_session` |
| `filter_chip_impression` | UC-01 | `keyword_filter_chips` | `tag`, `position_in_session` |
| `filter_chip_click` | UC-01 | `keyword_filter_chips` | `tag`, `position_in_session` |
| `friends_first_impression` | UC-02 | `friends_first_header` | `proximity_score` |
| `friends_first_click` | UC-02 | `friends_first_header` | `friend_count` |
| `story_view` | UC-02 | `story_inline_reply_chip` | `tag` |
| `inline_reply_send` | UC-02 | `story_inline_reply_chip` | `share_channel` |
| `template_suggestion_impression` | UC-03 | `template_suggestion_composer` | `tag` |
| `template_use` | UC-03 | `template_suggestion_composer` | `template_id` |
| `hint_impression` | UC-03 | `best_time_to_post_hint` | `position_in_session` |
| `post_publish` | UC-03 | `best_time_to_post_hint` | `media_count` |
| `suggestion_impression` | UC-04 | `query_suggestions_search` | `position` |
| `suggestion_click` | UC-04 | `query_suggestions_search` | `query` |
| `hashtag_panel_open` | UC-04 | `hashtag_overview_panel` | `tag` |
| `hashtag_follow` | UC-04 | `hashtag_overview_panel` | `tag` |
| `rules_view` | UC-05 | `group_rules_pinned` | `group_id` |
| `rule_acknowledge` | UC-05 | `group_rules_pinned` | `group_id` |
| `invite_sent` | UC-05 | `event_invite_via_dm` | `event_id`, `share_channel` |
| `invite_accept` | UC-05 | `event_invite_via_dm` | `event_id` |
| `alert_impression` | UC-06 | `saved_filter_alert_market` | `alert_id`, `tag` |
| `listing_click` | UC-06 | `saved_filter_alert_market` | `listing_id`, `position_in_session` |
| `price_drop_impression` | UC-06 | `price_drop_banner` | `listing_id`, `price_drop_pct` |
| `price_drop_click` | UC-06 | `price_drop_banner` | `listing_id`, `price_drop_pct` |
| `purchase_intent` | UC-06 | `price_drop_banner` | `amount`, `currency` |
| `tune_feed_prompt` | UC-07 | `tune_your_feed_prompt` | `proximity_score` |
| `tune_action` | UC-07 | `tune_your_feed_prompt` | `selected_topic` |
| `muted_word_suggestion` | UC-07 | `muted_words_suggest` | `word` |
| `muted_word_add` | UC-07 | `muted_words_suggest` | `word` |
