---
title: Caffeinate
description: Keep your Mac awake for a while, until a time, or while an app is running.
---

**Caffeinate** keeps your Mac from going to sleep. One hold runs at a time. Starting another replaces
the one that's running.

Closing the launcher does not stop it. Quitting Tinycast does.

The commands are in **Settings → Commands**. You can give any of them a shortcut or an alias.
Press the shortcut for an open screen again to close it.

## Commands

| Command | What it does |
| --- | --- |
| Caffeinate | Keep the Mac awake until you stop it |
| Decaffeinate | Let the Mac sleep |
| Toggle Caffeinate | Start an open-ended hold, or stop the one that's running |
| Caffeinate for… | Pick a duration, or type one |
| Caffeinate Until | Keep the Mac awake until a time |
| Caffeinate While | Keep the Mac awake while an app or a process is running |
| Caffeinate Status | See whether the Mac is being kept awake |

**Caffeinate Status** says what the current hold is doing. With no hold, it says the Mac can sleep.

## For a duration

Run **Caffeinate for…** and pick 5 minutes, 15 minutes, 30 minutes, 1 hour, 2 hours or 4 hours. Or
type the duration.

A number on its own is minutes, so `30` is 30 minutes and `1.5` is a minute and a half. You can
also write `90m`, `1h`, `1h30m`, `45s` or `1 hour 30 minutes`. The decimal mark is a point.

The shortest hold is one second. The longest is 24 hours.

## Until a time

Run **Caffeinate Until** and type a time, such as `5pm`, `5:30 pm`, `17:30` or `9`. `noon` and
`midnight` work too.

A time that has already passed today is taken as tomorrow. `tomorrow 9am` is always the next day.
`tomorrow` has to come first: `5pm tomorrow` is not a time.

## While something is running

Run **Caffeinate While**. With nothing typed, the screen lists the apps that are running. Type a
name to narrow them, or type a process name or a pid.

The hold follows that process. When it exits, the Mac can sleep. Opening the app again does not
start the hold over.

## The menu bar

While a hold is active, a cup sits in the menu bar. An open-ended hold shows the cup on its own. A
timed hold shows the time left, and a process hold shows the process name. The menu names the hold
and has **Decaffeinate**.

## What stays awake

**Settings → Commands → Caffeinate** chooses what the hold blocks.

| Setting | Default |
| --- | --- |
| Prevent display sleep | On. The screen stays on |
| Prevent system sleep | On. The Mac doesn't idle-sleep, and the screen can still turn off |
| Prevent disk sleep | Off. Disks stay spun up, which uses more power |
| Show in menu bar | On |

Turn all three sleep settings off and a hold won't start. One that's already running stops.

Caffeinate does not keep the Mac awake when you close the lid.
