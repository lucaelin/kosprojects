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

  launch["launch"]().

  launch["setStagecontroller"](true).

  print "Targeting IOTA.".
  set TARGET to BODY("Iota").


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
  wait until STAGE:READY.
  stage.
  wait 1.
  wait until STAGE:READY.
  wait 1.
  stage.
  wait until STAGE:READY.
  wait 20.
  // </wtf>
  lock STEERING to RETROGRADE.
  wait 20.
  set KUNIVERSE:TIMEWARP:RATE to 1000.
  wait until SHIP:BODY = BODY("Iota").
  KUNIVERSE:TIMEWARP:CANCELWARP().
  wait until KUNIVERSE:TIMEWARP:ISSETTLED.
  wait 10.

  print "Adjusting periapsis.".
  if PERIAPSIS > -BODY:RADIUS/2 {
    lock STEERING to RADIALIN.
    wait 10.
    lock THROTTLE to 1.
    wait until PERIAPSIS < 0.
    lock THROTTLE to 0.5.
    wait until PERIAPSIS < -BODY:RADIUS*0.9.
    lock THROTTLE to 0.
  }
  lock STEERING to HEADING(0, 0).
  wait 10.
  lock THROTTLE to 1.
  wait until PERIAPSIS > 250000.
  lock THROTTLE to 0.
  wait 1.

  print BODY:NAME + " orbit insertion.".
  maneuver["capture"]().
  wait 1.
  maneuver["circularize"](true).

  wait 1.

  TOGGLE AG4.
}
