{
  local landing is import("lib/landing").
  local launch is import("lib/launch").
  local maneuver is import("lib/maneuver").
  local docking is import("lib/docking").
  local orbit is import("lib/orbit").
  local math is import("lib/math").

  launch["verticalAscend"](200).
  lock THROTTLE to 0.
  lock STEERING to UPTOP.
  wait until SHIP:VERTICALSPEED < 0.

  when ALT:RADAR < 1000 then {
    GEAR on.
  }

  local tgt is "somewhere".
  local thrott is 0.8.
  local height is 4.2.
  local AoA is 60.
  local hThrott is 0.8.
  local lookahead is 0.5.
  local bodylift is true.
  local ttiMult is 0.0.

  landing["land"](tgt, thrott, height, AoA, hThrott, lookahead, bodylift, ttiMult).

  lock STEERING to UPTOP.
}
