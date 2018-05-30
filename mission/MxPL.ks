{
  local landing is import("lib/landing").
  local launch is import("lib/launch").
  local maneuver is import("lib/maneuver").
  local docking is import("lib/docking").
  local orbit is import("lib/orbit").

  set TARGET to BODY("Iota").
  local lan is TARGET:ORBIT:LAN.
  local inc is TARGET:ORBIT:INCLINATION.

  local obt is LEX(
    "LAN", lan,
    "INC", inc
  ).

  local launcher to PROCESSOR("launcher").
  launcher:CONNECTION:SENDMESSAGE(obt).

  recvMsg().
  set SHIPNAME to SHIPNAME:SPLIT(" @ ")[0].

  launch["setStagecontroller"](true).

  set TARGET to BODY("Iota").
  print "Targeting " + TARGET:NAME + ".".


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
  wait 10.
  until STAGE:NUMBER = 1 {
    wait until STAGE:READY.
    stage.
    wait 1.
  }

  lock STEERING to RETROGRADE.
  wait 20.
  set KUNIVERSE:TIMEWARP:RATE to 1000.
  wait until SHIP:BODY = BODY("Iota").
  KUNIVERSE:TIMEWARP:CANCELWARP().
  wait until KUNIVERSE:TIMEWARP:ISSETTLED.
  wait 10.

  print "Adjusting periapsis.".
  if PERIAPSIS > 20000 {
    lock STEERING to RETROGRADE.
    wait 10.
    lock THROTTLE to 1.
    wait until PERIAPSIS < 40000.
    lock THROTTLE to 0.5.
    wait until PERIAPSIS < 20000.
    lock THROTTLE to 0.
  }
  lock STEERING to PROGRADE.
  wait 10.
  lock THROTTLE to 1.
  wait until PERIAPSIS > 0.
  lock THROTTLE to 0.5.
  wait until PERIAPSIS > 20000.
  lock THROTTLE to 0.
  wait 1.

  print BODY:NAME + " orbit insertion.".
  maneuver["capture"]().
  wait 1.
  maneuver["circularize"](true).
  maneuver["circularize"]().

  awaitInput().

  maneuver["escape"](180, 300).

  maneuver["changePe"](math["meanToTrue"](270), BODY:ATMHEIGHT/2).

  wait 1.
  print BODY:NAME + " landing.".
  landing["parachute"]().
  TOGGLE AG4.
}
