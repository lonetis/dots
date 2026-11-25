# jq definitions for the JSON list of displays from `omniwmctl query displays`, loaded by
# displays.sh. Frames use AppKit coordinates: the origin is the bottom-left corner of the
# main display and y grows upwards.

def center: [.frame.x + .frame.width / 2, .frame.y + .frame.height / 2];

def by_id($id): first(.[] | select(.id == $id));

# Grid cell [column, row] per display id, chosen the way OmniWM picks a saved
# arrangement, or null when routing follows the macOS arrangement.
def grid($routing):
  . as $displays
  | if $routing.mode != "custom" then null
    else
      [ $routing.arrangements[] as $rows
        | [ $displays[] as $display
            | ( first($rows[] | select(.monitorDisplayUUID == $display.uuid))
                // first($rows[] | select(.monitorDisplayUUID == null and .monitorName == $display.name))
                // null ) as $row
            | if $row == null then null else {key: $display.id, value: [$row.gridColumn, $row.gridRow]} end ]
        | select(all(. != null))
        | from_entries
        | select(length == ($displays | length) and ([.[]] | unique | length) == length)
        | {rank: [($rows | length) != ($displays | length), ($rows | length)], cells: .} ]
      | if length == 0 then null else min_by(.rank).cells end
    end;

# The display OmniWM moves to from $origin in $direction (no wrap-around), or null.
def neighbor($origin; $direction; $grid):
  map(select(.id != $origin.id))
  | if $grid != null then
      $grid[$origin.id] as [$col, $row]
      | map(. as $display
          | $grid[.id] as [$c, $r]
          | ( if ($direction == "left" or $direction == "right") and $r == $row then
                (if $direction == "right" then $c - $col else $col - $c end)
              elif ($direction == "up" or $direction == "down") and $c == $col then
                (if $direction == "up" then $row - $r else $r - $row end)
              else null end ) as $offset
          | select($offset != null and $offset > 0)
          | {rank: $offset, display: $display})
    else
      ($origin | center) as [$ox, $oy]
      | map(. as $display
          | center as [$x, $y]
          | ($x - $ox) as $dx | ($y - $oy) as $dy
          | ($dx | fabs) as $adx | ($dy | fabs) as $ady
          | ( if (($direction == "left" and $dx < 0) or ($direction == "right" and $dx > 0)) and $adx >= $ady then
                [$adx, $ady, $dx * $dx + $dy * $dy]
              elif (($direction == "up" and $dy > 0) or ($direction == "down" and $dy < 0)) and $ady >= $adx then
                [$ady, $adx, $dx * $dx + $dy * $dy]
              else null end ) as $rank
          | select($rank != null)
          | {rank: $rank, display: $display})
    end
  | if length == 0 then null else min_by(.rank).display end;

# Directions that lead from $source to $target, one per adjacent-monitor hop, or null.
def route($source; $target; $grid):
  . as $displays
  | def step:
      if (.queue | length) == 0 then null
      else
        .queue[0] as $id
        | .queue |= .[1:]
        | if $id == $target.id then .paths[$id]
          else
            ($displays | by_id($id)) as $display
            | reduce ("left", "right", "up", "down") as $direction (.;
                ($displays | neighbor($display; $direction; $grid)) as $next
                | if $next != null and .paths[$next.id] == null then
                    .paths[$next.id] = .paths[$id] + [$direction] | .queue += [$next.id]
                  else . end)
            | step
          end
      end;
    {queue: [$source.id], paths: {($source.id): []}} | step;

# The display $step places after the one with id $origin_id, wrapping around. Next and
# previous go along the grid rows, or from left to right without a grid.
def cycle_display($origin_id; $step; $grid):
  ( if $grid != null then sort_by([$grid[.id][1], $grid[.id][0]])
    else sort_by(center | [.[0], -.[1]]) end ) as $ordered
  | ($ordered | length) as $count
  | ($ordered | map(.id) | index($origin_id)) as $index
  | $ordered[(($index + $step) % $count + $count) % $count];
