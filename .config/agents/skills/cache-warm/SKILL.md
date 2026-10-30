---
name: cache-warm
description: >
  Claude Code only. Keep this session's prompt cache warm while the user steps
  away, so coming back doesn't pay a full cache rewrite. Use when the user says
  "cache-warm", "keep the cache warm", "hold the cache", "keepwarm", "I'll be
  back in N hours", or asks to stop/cancel a running cache hold. Takes an
  optional duration ("2h", "90m", "until 18:00"); default 2h.
---

The subscription caches prompts for 1 hour. Any request that reads the cache
also resets that hour, so one short turn every 50 minutes keeps the cache warm.
Each ping costs one cache read (0.1× input price). A cold return costs a full
rewrite at the 1h rate (2× input price), so one rewrite costs as much as about
20 hours of pings. The statusline's 󰔟 chip counts down from the newest
response, so it shows each ping landing.

## Start

1. Parse the duration (default 2h). The count is `ceil(duration / 50m)`.
2. Work out the fire times in one shell call, so `date` handles midnight and
   month rollover:
   ```sh
   for i in $(seq 1 N); do date -d "+$((i*50)) min" '+%M %H %d %m'; done
   ```
   If a time lands on minute `00` or `30`, move it one minute earlier. One-shot
   jobs at those minutes can fire up to 90 s early, and the fleet bunches there.
3. Create one `CronCreate` job per time with `recurring: false`, cron
   `"<M> <H> <DoM> <Mon> *"`, and exactly this prompt:
   `cache-warm ping: reply with the single word "warm". No tools, no other text.`
   Pin every time up front instead of using a recurring job. Recurring jobs
   can fire up to 10% of their period late, which leaves a 66-minute gap
   against the 60-minute TTL. Pinned one-shots fire on time and end on their
   own when the hold runs out.
4. Tell the user in one line: how many pings, when the last one fires, and
   that `/cache-warm stop` cancels it.

## Ping

When a turn's prompt is the ping prompt, reply `warm` and nothing else. Do not
resume pending work, call tools, or comment. Any extra text costs output tokens
and pulls the user's attention for nothing.

## Stop

On "stop", "cancel" or "cold": run `CronList`, delete every job whose prompt
starts with `cache-warm ping`, then say how many you removed.

## Limits

- Jobs exist only in this session. Exiting Claude Code, `/clear` or a
  compaction ends the hold. After `/clear` or a compaction the context is new
  anyway, so warming the old prefix buys nothing.
- Pings fire only while the REPL is idle. A ping that comes due mid-turn waits
  in the queue, and that turn has already warmed the cache.
- Don't start a hold just to keep the cache warm between your own wakeups
  (`/loop`, `ScheduleWakeup`). Those already land inside the TTL.
