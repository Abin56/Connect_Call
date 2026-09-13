# ConnectCall — Figma Mockup → Codebase Mapping

The Figma mockup uses a blue/purple/dark-navy palette. The app's actual
implemented theme ("Theme V2", [lib/core/theme/app_colors.dart](lib/core/theme/app_colors.dart))
is lime accent (`#C6F24E`) on near-black / off-white surfaces. Colors below
reference the real theme, not the mockup's.

| # | Mockup screen | Status | Implementation |
|---|---|---|---|
| 1 | Splash Screen | ✅ Built | [lib/features/splash/splash_screen.dart](lib/features/splash/splash_screen.dart) |
| 2 | Login Screen | ✅ Built | [lib/features/auth/login_screen.dart](lib/features/auth/login_screen.dart) |
| 3 | Registration Screen | ✅ Built | [lib/features/auth/register_screen.dart](lib/features/auth/register_screen.dart) |
| 4 | Home Screen (greeting, stats, recent calls) | ✅ Built | [lib/features/home/home_tab.dart](lib/features/home/home_tab.dart) — no "Your Calls" stat tiles (Total/Outgoing/Incoming counts); only greeting header, search, quick actions, recent calls, contacts preview |
| 5 | Contacts Screen | ✅ Built | [lib/features/contacts/contacts_screen.dart](lib/features/contacts/contacts_screen.dart) |
| 6 | Profile Screen | ✅ Built | [lib/features/profile/profile_screen.dart](lib/features/profile/profile_screen.dart) — has Edit Profile/Logout; no separate "Appearance"/"Dark Mode" preference rows currently |
| 7 | Call History Screen | ✅ Built | [lib/features/history/call_history_screen.dart](lib/features/history/call_history_screen.dart) — grouped by day; mockup's All/Audio/Video/Missed filter chips not present |
| 8 | Incoming Call Screen | ⚙️ Provided by ZEGO | Not a custom Flutter screen — rendered by `zego_uikit_prebuilt_call`'s invitation UI, configured in [lib/features/calling/call_config_builder.dart](lib/features/calling/call_config_builder.dart) |
| 9 | Audio Call Screen | ⚙️ Provided by ZEGO | `ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall()` |
| 10 | Video Call Screen | ⚙️ Provided by ZEGO | `ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()` |
| 11 | Call States (calling/ringing/connected/etc.) | ✅ Modeled, not a screen | [lib/models/call_model.dart](lib/models/call_model.dart) `CallStatus` enum covers all 8 states shown; states are surfaced via ZEGO's UI + [call_history_tile.dart](lib/features/history/widgets/call_history_tile.dart), not a dedicated states screen |
| 12 | Offline Experience | ✅ Built (as banner, not full-screen) | [lib/core/widgets/offline_banner.dart](lib/core/widgets/offline_banner.dart) — non-blocking top banner shown across [home_screen.dart](lib/features/home/home_screen.dart) rather than a full-screen "No internet connection / Try Again" state |

## Reusable primitives already available for call UI
- [lib/core/widgets/call_control_button.dart](lib/core/widgets/call_control_button.dart) — `CallControlButton` (neutral/active/danger/accept variants) and `CallControlDock`, styled for a custom call screen but currently unused since ZEGO's prebuilt UI is used instead.
- [lib/core/widgets/user_avatar.dart](lib/core/widgets/user_avatar.dart) — avatar with online-status dot, used across Home/Contacts/Profile.

## Gaps vs. mockup (if pursuing pixel parity)
- No stat-tile row (Total/Outgoing/Incoming call counts) on Home.
- No filter chips (All/Audio/Video/Missed) on Call History.
- No Appearance/Dark Mode preference rows on Profile (dark theme exists in `AppColorsDark` but isn't user-toggleable yet).
- No full-screen offline state — only a banner.
- Custom incoming/audio/video call screens don't exist; ZEGO's prebuilt UI is used instead, so `CallControlButton`/`CallControlDock` are currently dead code unless a custom call screen replaces ZEGO's UI.
