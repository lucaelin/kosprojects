{
  local launch is import("lib/launch").
  local maneuver is import("lib/maneuver").
  local orbit is import("lib/orbit").

  maneuver["adjustArgument"]().

  wait until false.
}
