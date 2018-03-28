{
  set SHIPNAME to SHIPNAME:SPLIT(" @ ")[0].

  local launch is import("lib/launch").
  local maneuver is import("lib/maneuver").

  launch["setStagecontroller"](true).

  wait 10.

  maneuver["raiseOrbit"](200000).
  maneuver["circularize"]().

  lock STEERING to PROGRADE.

  wait 10.
  until STAGE:NUMBER = 0 {
    wait until STAGE:READY.
    stage.
    wait 1.
  }

  unlock STEERING.
  unlock THROTTLE.
  SAS on.
}
