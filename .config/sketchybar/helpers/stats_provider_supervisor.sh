#!/bin/sh
# Keep stats_provider alive for sketchybar.
#
# stats_provider exits as soon as it cannot reach sketchybar, which happens on every
# bar reload. Spawned as a plain detached child it then stays dead until sketchybar is
# restarted by hand -- the reason the bar used to stop updating. This loop restarts it.
#
# Stale instances are matched by this script's own path instead of a pidfile: the
# config directory is hotloaded, so writing state into it would retrigger reloads.

set -u

PROVIDER="${SKETCHYBAR_STATS_PROVIDER:-/opt/homebrew/bin/stats_provider}"
RESTART_DELAY="${SKETCHYBAR_STATS_RESTART_DELAY:-5}"
SELF="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"

# Fail loudly rather than spinning silently on a missing or moved binary.
if [ ! -x "$PROVIDER" ]; then
	echo "stats_provider_supervisor: no executable at $PROVIDER" >&2
	exit 1
fi

# Replace the supervisor left over from a previous config load, plus the provider it
# owned, so reloads never accumulate duplicates.
for pid in $(pgrep -f "$SELF" 2>/dev/null); do
	[ "$pid" = "$$" ] || kill "$pid" 2>/dev/null
done
pkill -f "$PROVIDER" 2>/dev/null

child=""
trap '[ -n "$child" ] && kill "$child" 2>/dev/null; exit 0' TERM INT

while :; do
	# Output is discarded because this loop *is* the handler for the only routine
	# error it emits ("Failed to get response from sketchybar" while the bar reloads);
	# logging it every few seconds would refill the log this config once overflowed.
	"$PROVIDER" \
		--battery percentage remaining state time_to_full \
		--cpu count frequency temperature usage \
		--disk count free total usage used \
		--memory ram_available ram_total ram_usage ram_used swp_free swp_total swp_usage swp_used \
		--system arch distro host_name kernel_version name os_version long_os_version \
		--uptime day hour \
		--interval 1 \
		--no-units \
		>/dev/null 2>&1 &
	child=$!
	wait "$child"
	child=""
	sleep "$RESTART_DELAY"
done
