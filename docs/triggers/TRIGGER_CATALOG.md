# App-Origin Trigger Catalog

## next_up_rail
- **id:** `next_up_rail`
- **name:** Next Up Rail
- **surface:** Shorts / ForYou
- **eligibility:** Completed shorts ratio ≥ 0.9, cooldown 30 minutes
- **when_it_fires:** `video_complete`
- **frequency_cap:** 3 per session, 8 per day
- **priority:** 90
- **flag_key:** `triggers.next_up.enabled`
- **dismiss_behavior:** remember for session
- **metrics:** `video_complete`, `next_up_click`, `session_length_delta`
- **rollback_notes:** Disable flag and clear impression cache

## keyword_filter_chips
- **id:** `keyword_filter_chips`
- **name:** Keyword Filter Chips
- **surface:** ForYou
- **eligibility:** Feed contains trending keywords
- **when_it_fires:** `feed_load`
- **frequency_cap:** 1 per session, 5 per day
- **priority:** 70
- **flag_key:** `triggers.keyword_filter_chips`
- **dismiss_behavior:** hide for a day
- **metrics:** `filter_chip_impression`, `filter_chip_click`
- **rollback_notes:** Disable flag

## friends_first_header
- **id:** `friends_first_header`
- **name:** Friends First Header
- **surface:** Home Feed
- **eligibility:** Feed has recent friend posts
- **when_it_fires:** `feed_open`
- **frequency_cap:** 2 per session, 6 per day
- **priority:** 80
- **flag_key:** `triggers.friends_first_header`
- **dismiss_behavior:** remember for session
- **metrics:** `friends_first_impression`, `friends_first_click`, `session_length_delta`
- **rollback_notes:** Disable flag and remove header

## story_inline_reply_chip
- **id:** `story_inline_reply_chip`
- **name:** Story Inline Reply Chip
- **surface:** Stories
- **eligibility:** Viewer can send DMs
- **when_it_fires:** `story_view`
- **frequency_cap:** 5 per session, 15 per day
- **priority:** 60
- **flag_key:** `triggers.story_inline_reply_chip`
- **dismiss_behavior:** hide for session
- **metrics:** `story_view`, `inline_reply_send`
- **rollback_notes:** Disable flag

## template_suggestion_composer
- **id:** `template_suggestion_composer`
- **name:** Template Suggestion in Composer
- **surface:** Composer
- **eligibility:** Draft has no media or text
- **when_it_fires:** `composer_open`
- **frequency_cap:** 2 per session, 4 per day
- **priority:** 50
- **flag_key:** `triggers.template_suggestion`
- **dismiss_behavior:** remember per device
- **metrics:** `template_suggestion_impression`, `template_use`
- **rollback_notes:** Disable flag

## best_time_to_post_hint
- **id:** `best_time_to_post_hint`
- **name:** Best Time to Post Hint
- **surface:** Composer
- **eligibility:** Account has audience data
- **when_it_fires:** `composer_open`
- **frequency_cap:** 1 per day
- **priority:** 55
- **flag_key:** `triggers.best_time_to_post`
- **dismiss_behavior:** hide for 24h
- **metrics:** `hint_impression`, `post_publish`
- **rollback_notes:** Disable flag

## hashtag_overview_panel
- **id:** `hashtag_overview_panel`
- **name:** Hashtag Overview Panel
- **surface:** Search
- **eligibility:** Query contains `#`
- **when_it_fires:** `search_submit`
- **frequency_cap:** 5 per day
- **priority:** 65
- **flag_key:** `triggers.hashtag_overview`
- **dismiss_behavior:** remember for query
- **metrics:** `hashtag_panel_open`, `hashtag_follow`
- **rollback_notes:** Disable flag

## query_suggestions_search
- **id:** `query_suggestions_search`
- **name:** Query Suggestions in Search
- **surface:** Search
- **eligibility:** Empty search box focus
- **when_it_fires:** `search_focus`
- **frequency_cap:** unlimited per session
- **priority:** 40
- **flag_key:** `triggers.query_suggestions`
- **dismiss_behavior:** hide for session
- **metrics:** `suggestion_impression`, `suggestion_click`
- **rollback_notes:** Disable flag

## group_rules_pinned
- **id:** `group_rules_pinned`
- **name:** Group Rules Pinned
- **surface:** Groups
- **eligibility:** User is group member
- **when_it_fires:** `group_open`
- **frequency_cap:** 1 per group per day
- **priority:** 75
- **flag_key:** `triggers.group_rules`
- **dismiss_behavior:** remember acknowledgment
- **metrics:** `rules_view`, `rule_acknowledge`
- **rollback_notes:** Disable flag

## event_invite_via_dm
- **id:** `event_invite_via_dm`
- **name:** Event Invite via DM
- **surface:** Events
- **eligibility:** User RSVP'd "going"
- **when_it_fires:** `rsvp_success`
- **frequency_cap:** 3 per event
- **priority:** 70
- **flag_key:** `triggers.event_invite_dm`
- **dismiss_behavior:** remember per event
- **metrics:** `invite_sent`, `invite_accept`
- **rollback_notes:** Disable flag

## saved_filter_alert_market
- **id:** `saved_filter_alert_market`
- **name:** Saved Filter Alert in Marketplace
- **surface:** Marketplace
- **eligibility:** User has saved search filter
- **when_it_fires:** `price_match`
- **frequency_cap:** 5 per day
- **priority:** 60
- **flag_key:** `triggers.saved_filter_alert`
- **dismiss_behavior:** hide for 24h
- **metrics:** `alert_impression`, `listing_click`
- **rollback_notes:** Disable flag

## price_drop_banner
- **id:** `price_drop_banner`
- **name:** Price Drop Banner
- **surface:** Marketplace
- **eligibility:** Saved item drops price ≥10%
- **when_it_fires:** `price_drop_detected`
- **frequency_cap:** 2 per item per day
- **priority:** 85
- **flag_key:** `triggers.price_drop`
- **dismiss_behavior:** remember per item
- **metrics:** `price_drop_impression`, `price_drop_click`, `purchase_intent`
- **rollback_notes:** Disable flag

## tune_your_feed_prompt
- **id:** `tune_your_feed_prompt`
- **name:** Tune Your Feed Prompt
- **surface:** Feed Settings
- **eligibility:** User reported irrelevant content
- **when_it_fires:** `settings_open`
- **frequency_cap:** 1 per session
- **priority:** 50
- **flag_key:** `triggers.tune_feed`
- **dismiss_behavior:** hide for session
- **metrics:** `tune_feed_prompt`, `tune_action`
- **rollback_notes:** Disable flag

## muted_words_suggest
- **id:** `muted_words_suggest`
- **name:** Muted Words Suggestion
- **surface:** Safety Settings
- **eligibility:** Recent negative interactions
- **when_it_fires:** `settings_open`
- **frequency_cap:** 1 per day
- **priority:** 45
- **flag_key:** `triggers.muted_words_suggest`
- **dismiss_behavior:** remember per word
- **metrics:** `muted_word_suggestion`, `muted_word_add`
- **rollback_notes:** Disable flag
