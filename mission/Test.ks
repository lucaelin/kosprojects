{
  local maneuver is import("lib/maneuver").
  local math is import("lib/math").
  local docking is import("lib/docking").

  set TARGET to VESSEL("Untitled Space Craft").
  wait 0.
  stage.
  wait until STAGE:READY.

  maneuver["simpleTransfer"]().
}
