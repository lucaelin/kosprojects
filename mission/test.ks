{
  local maneuver is import("lib/maneuver").

  wait 0.
  wait until STAGE:READY.
  stage.
  wait until STAGE:READY.

  maneuver["escape"](542.5, 180).
}
