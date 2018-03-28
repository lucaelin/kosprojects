{
  local launch is import("lib/launch").
  local maneuver is import("lib/maneuver").
  local landing is import("lib/landing").
  when ALTITUDE > 55000 THEN {
    TOGGLE AG1.
    when ALTITUDE > 70000 THEN {
      TOGGLE AG2.
    }
  }

  set MAXSTAGE to STAGE:NUMBER.

  set TARGET to BODY("Ceti").
  launch["launchTarget"]().

  launch["setStagecontroller"](true).

  print "Adjusting inclination.".
  maneuver["tgtInclination"]().
  print "Adjusting inclination again.".
  maneuver["tgtInclination"]().
  print "Circularizing again.".
  maneuver["circularize"]().
  print "Transfering to " + TARGET:NAME + ".".
  maneuver["simpleTransfer"]().

  wait 10.
  print "Payload deploy.".
  TOGGLE AG3.

  lock STEERING to RADIALIN.
  // <wtf>
  wait 10.
  timeout({
    stage.
    timeout({
      stage.
    }, 1).
  }).
  wait 5.
  wait until STAGE:READY.
  stage.
  wait until STAGE:READY.
  wait 5.
  stage.
  wait 20.
  // </wtf>
  lock STEERING to RETROGRADE.
  wait 20.
  set KUNIVERSE:TIMEWARP:RATE to 1000.
  local tgt is TARGET.
  wait until SHIP:BODY = tgt.
  KUNIVERSE:TIMEWARP:CANCELWARP().
  wait until KUNIVERSE:TIMEWARP:ISSETTLED.
  wait 10.

  print "Adjusting periapsis.".
  if PERIAPSIS < 10000 {
    lock STEERING to RADIALOUT.
    wait 10.
    lock THROTTLE to 0.5.
    wait until PERIAPSIS > 15000.
  } else {
    lock STEERING to RADIALIN.
    wait 10.
    lock THROTTLE to 0.5.
    wait until PERIAPSIS < 15000.
  }
  lock THROTTLE to 0.
  wait 1.

  print BODY:NAME + " orbit insertion.".
  maneuver["capture"]().
  wait 1.
  maneuver["circularize"](true).

  wait 1.
  wait until ADDONS:SCANSAT:CURRENTBIOME = "Highlands".

  print "Breaking orbit.".
  landing["breakOrbit"]().
  wait 1.
  print BODY:NAME + " landing.".
  landing["land"](1).

  print "Jettison Skycrane.".

  local e is LIST().
  list ENGINES in e.
  set e to e[0].

  lock THROTTLE to 1.0.
  wait until e:THRUST > e:AVAILABLETHRUST * THROTTLE * 0.9.
  timeout({
    toggle AG4.
    BRAKES on.
  }).

  wait 5.
  unlock STEERING.
  unlock THROTTLE.
}
