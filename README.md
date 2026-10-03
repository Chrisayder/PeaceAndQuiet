# Peace and Quiet

Political chat filter for WoW Forever beta. Turn it on, choose which chats to filter, and adjust the blocked terms to your liking.

**Version 1.9.3.1** · Interface 16001

## Installation

Download this repository using **Code → Download ZIP**. Extract it and copy the inner `PeaceAndQuiet` folder into your WoW client's `Interface/AddOns` folder. For Forever beta, this is usually under `_classic_beta_`.

You should end up with `Interface/AddOns/PeaceAndQuiet/PeaceAndQuiet.toc`. Restart the game and enable **Peace and Quiet** in the addon list.

## Using it

Left-click the **PQ** minimap button for settings. Right-click to see blocked messages. You can also open settings with `/pq options`.

- Choose which chats to filter: public, guild, group, whispers, or communities.
- Search the term list and uncheck or delete anything you want to keep seeing.
- Add your own words or phrases by typing them and pressing Enter.
- Turn on aggressive filtering to catch more terms. It can also catch harmless conversations, so adjust the list as needed.
- Check **Filtered Chat** to see what was blocked and why. The last 500 messages are saved between sessions.
- Open **Performance** to see memory usage and filter timings.

**Guild blocking is still a work in progress.** Guild detection is unreliable and can miss players.

## Commands

| Command | What it does |
| --- | --- |
| `/pq options` | Open settings |
| `/pq on` / `/pq off` | Enable or pause filtering |
| `/pq log` | Open blocked-message history |
| `/pq status` | Show filtering activity |
| `/pq test MESSAGE` | Test a message without sending it |
| `/pq perf` | Show performance readings |
| `/pq clear` | Clear blocked-message history |

See the [user guide](PeaceAndQuiet/README.md) for more settings and commands.

## A few things to know

The filter matches English words and phrases. It will sometimes miss a political message or block an innocent one. It only changes your chat display; chat bubbles and other addons may still show the original message.

Settings and blocked messages, including filtered whispers, stay in WoW's local SavedVariables. Nothing is sent to an external service. Use `/pq clear` to erase the history.

Found a bug? [Open an issue](https://github.com/Chrisayder/PeaceAndQuiet/issues) with your addon version, WoW build, and any Lua error. For display problems, mention any other chat or minimap addons you use. Please leave private chat out of screenshots.

## Development

Run the tests from the repository root with Python 3.12 or newer:

```sh
python -m pip install -r requirements-dev.txt
python tests/test_iconfix.py
```

The tests use Lua 5.1 with mocked WoW APIs. Changes still need testing in-game.

Run `python package.py` to build an installable ZIP in `dist/`.
