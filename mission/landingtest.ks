{
  local launch is import("lib/launch").
  local landing is import("lib/landing").

  //toggle GEAR.
  toggle AG1.
  launch["verticalAscend"](500, 1.0).

  lock THROTTLE to 0.

  wait until SHIP:VERTICALSPEED < 0.
  stage.
  wait 1.

  local tgt is VESSEL(SHIPNAME + " Probe").
  local thrott is 0.8.
  local height is 2.5.
  local AoA is 45.
  local hThrott is 0.1.
  local lookahead is 0.8.
  local bodylift is true.
  local ttiMult is 0.0.

  landing["land"](tgt, thrott, height, AoA, hThrott, lookahead, bodylift, ttiMult).

  lock STEERING to UPTOP.

  wait until false.
}
