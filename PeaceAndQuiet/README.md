# Peace and Quiet

Version 1.9.3.1 for WoW Forever beta (interface 16001).

## Install

Close WoW and copy the `PeaceAndQuiet` folder into your client's `Interface/AddOns` folder. For Forever beta, this is usually `World of Warcraft/_classic_beta_/Interface/AddOns`. Restart the game and enable the addon. Updating the addon keeps your saved settings and history.

## Settings

Left-click the **PQ** minimap button or type `/pq options`. Right-click the button to open **Filtered Chat**. Drag it to move it around the minimap.

Choose which chats to filter under Settings. All chat groups start enabled. Aggressive filtering includes broader terms that can also appear in normal conversation. Turn it off for a narrower set of filters.

### Filter terms

Open **Manage filter terms** to search the list. Checked terms are enabled. Unchecked terms stay in the list so you can turn them back on later. Aggressive-only terms remain visible when aggressive filtering is off, and you can enable them individually.

To add a term, type it into **Add a custom blocked term** and press Enter or click **Add term**. The confirmation tells you whether it was added, enabled, or already filtered.

**Delete** removes a preset or custom term from the list and from filtering. **Undo delete** restores it during the current session. After a reload, you can restore a deleted term by adding it again. Unchecking or deleting one term won't allow a message through if it matches another active term.

Standalone `rfk` is not a default filter because it is also a dungeon abbreviation. `rfk jr` is still filtered. If you added `rfk` yourself, remove it from your custom terms to allow dungeon recruitment messages.

### Blocked messages

**Filtered Chat** shows blocked messages with the sender, channel, time, and matched rule. The last 500 entries are saved account-wide, including filtered whispers. Use `/pq clear` to clear them.

WoW saves the history on normal logout or `/reload`. The file is usually at `WTF/Account/YOUR_ACCOUNT/SavedVariables/PeaceAndQuiet.lua`. Use the in-game tab to watch messages as they are blocked. If WoW has no free chat tab, free one and run `/pq log`.

### Guilds (work in progress)

Guild blocking is unreliable. WoW does not provide guild membership with every message, so some players will be missed.

Enter a guild name and press Enter or click **Block guild**. Use the list to toggle or delete a guild. Names are case-insensitive for ordinary English letters, but punctuation must match. Guilds with the same name share a rule.

Membership is learned from visible players, group members, and results from the game's `/who` window. The addon does not send automatic `/who` requests. Learned membership expires after 10 minutes and clears on reload; your blocked-guild list is saved. **Clear learned membership** clears the current cache.

Guild filtering follows your enabled chat groups. It does not cover Battle.net messages, outgoing whispers, invites, voice, or mail.

### Performance

The Performance page shows addon memory, the highest sampled memory reading, and filter processing times. Blizzard's CPU reading appears when the client provides it and its profiler is enabled.

Filter timings cover matching and logging, not every part of the addon. Multiple chat windows can produce more than one filter call per message. These readings are milliseconds, not CPU percentages or an FPS measurement.

The page refreshes once per second; memory readings refresh at most every five seconds while viewing the page or requesting `/pq perf`. **Reset local measurements** resets timing counters and the sampled memory peak. It does not clear history or free memory.

## Commands

| Command | What it does |
| --- | --- |
| `/pq options` or `/pq config` | Open settings |
| `/pq on` / `/pq off` | Enable or pause filtering |
| `/pq status` | Show mode, chat groups, and activity counts |
| `/pq mode aggressive` / `/pq mode strict` | Set filter strength |
| `/pq log` | Open Filtered Chat |
| `/pq history` | Print the latest 20 saved entries |
| `/pq clear` | Clear saved history and the live tab |
| `/pq test MESSAGE` | Test matching without sending a message |
| `/pq add PHRASE` | Add and enable a custom term |
| `/pq remove PHRASE` | Remove a custom term; a matching preset may still apply |
| `/pq list` | List custom terms and disabled rules |
| `/pq perf` | Show performance readings |
| `/pq scope public\|guild\|group\|whispers\|community on\|off` | Enable or disable a chat group |

The older `/pq ignore PHRASE` and `/pq unignore PHRASE` commands are still supported for preset exceptions. The term manager is the easier way to change these settings.

## Known limitations

Matching is based on English words and phrases. It can miss slang, unusual spellings, and indirect references. Broad terms can hide innocent messages. System and NPC messages are not filtered. Chat bubbles, notifications, and third-party chat displays may bypass the filter.

Only your chat display changes; other players still receive messages normally. Settings and history stay on your computer, with no external services or telemetry.

## Recent changes

- **1.9.3.1:** Updated the user guide. No filtering changes.

- **1.9.3:** Removed the square minimap-button background that extended outside circular button collectors.
- **1.9.2:** Fixed a Lua error when Ellesmere's minimap collector treated the PQ text as a texture.
- **1.9.1:** Added the PQ minimap badge.
- **1.9.0:** Updated the settings panel and marked guild blocking as a work in progress.
- **1.8.0:** Added experimental guild blocking.
- **1.7.0:** Added the performance monitor.
- **1.6.1:** Removed the standalone RFK preset and added deletion feedback.
- **1.6.0:** Added term deletion, undo, and clearer confirmation messages.

Report bugs at https://github.com/Chrisayder/PeaceAndQuiet/issues. Include your WoW build, addon version, and any Lua error. Remove private chat from reports and screenshots.
