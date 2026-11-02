# Caffeinate

Keeps the Mac from idle sleep. One hold at a time: indefinitely, for a duration, until a clock time,
or while an app or process is running. Closing the palette does not release it. Quitting Tinycast
does, because the kernel drops a dead process's assertions.

The commands are unowned, so they live in Settings › Commands with the rest of the set no feature
switch governs. The section under them chooses what the hold blocks and whether the menu bar shows a
cup while one is active.

## Invariants

- **One hold.** A new request replaces the previous one. `CaffeineLimit` is the whole of how a hold
  can end: `.indefinite`, `.until(Date)`, `.whileRunning(pid:name:)`. A duration is stored as
  `.until` once it starts, so the menu bar and the kernel timeout share one deadline. A new way to
  end a hold is a new case, a watcher in `CaffeineCoordinator`, and a screen only if it asks for
  input. It is not a new `AppEntry.Kind` or a new `SettingsTab`.
- **The assertions are `IOPMAssertionCreateWithProperties` only.** The types are
  `PreventUserIdleDisplaySleep`, `PreventUserIdleSystemSleep` and `PreventDiskIdle`.
  `PreventSystemSleep` is unsupported and is not used, so closing the lid can still sleep the Mac.
  A swap creates the new set before releasing the old ids; a failure leaves the running hold.
- **Targets come from settings, and an empty set is not a hold.** Display and system default on,
  disk off. All three off refuses a new hold and clears a live one. Changing the targets under a
  live hold reacquires them. The menu-bar switch does not. `AppCore` tracks the four settings, so
  settings.json applies them with no pane open.
- **A while-running hold watches the pid it started with.** A relaunch of the same name is a
  different process and does not keep the hold. The kernel timeout exists only for `.until`, as a
  backstop if the deadline task never runs.
- **The palette has one mode, `.caffeinate`, and three screens.** Opening the screen that is already
  showing closes the palette. Opening a different one stays open and clears the query. The search
  prompt is read only while that mode is showing, so the coordinator stays lazy until the first use.

## Commands

| Command | Does |
| --- | --- |
| Caffeinate | Hold with no deadline |
| Decaffeinate | Release the hold |
| Toggle Caffeinate | Start an open-ended hold, or release the current one |
| Caffeinate for… | Presets, or a typed duration: `30`, `90m`, `1h30m`, `1 hour 30 minutes` |
| Caffeinate Until | A clock time: `5pm`, `17:30`, `tomorrow 9am`. A time already past rolls to the next day |
| Caffeinate While | Running apps, plus a typed process name or pid |
| Caffeinate Status | The current hold, or that the Mac can sleep |

A bare number is minutes. Units are `h`, `m` and `s`, and the words for them. The decimal mark is a
point. A hold shorter than a second or longer than 24 hours is refused: longer than a day is a
schedule, and this feature has none. `tomorrow` is accepted in English and in the translated word,
and only as a prefix.

Searching `coffee` or `caffeine` finds the commands. The words are keywords, and those two are
boosted, so the names do not have to contain them.

## Settings

| Setting | Default | Assertion |
| --- | --- | --- |
| Prevent display sleep | on | `PreventUserIdleDisplaySleep` |
| Prevent system sleep | on | `PreventUserIdleSystemSleep`. The display can still dim |
| Prevent disk sleep | off | `PreventDiskIdle`. Disks stay spun up, which costs battery |
| Show in menu bar | on | A template cup while a hold is active, with the time left, or the process name |

The cup's menu names the hold and offers Decaffeinate. It updates every 30 seconds, and every second
in the last minute. An open-ended hold shows the cup alone.

## What this is not

No schedules, no launch-at-login hold, and no assertion that keeps the Mac awake with the lid closed.
Those are a different feature. The Raycast Coffee extension can still run beside this one; nothing
here replaces its schedule commands.
