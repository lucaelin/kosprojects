{
  local landing is import("lib/landing").
  local launch is import("lib/launch").
  local maneuver is import("lib/maneuver").
  local docking is import("lib/docking").
  local orbit is import("lib/orbit").
  local math is import("lib/math").

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
  until STAGE:NUMBER = 2 {
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
  lock STEERING to RADIALOUT.
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
  
  local parent is SHIP:BODY:BODY.
  local newPeri is parent:ATM:HEIGHT/2.
  local newSMA is (SHIP:BODY:ALTITUDE + newPeri) / 2 + parent:RADIUS.
  local newVel is math["velAtRadius"](SHIP:BODY:ALTITUDE + parent:RADIUS, newSMA, parent:MU).
  maneuver["escape"](SHIP:BODY:ORBIT:VELOCITY:ORBIT:MAG-newVel, 180).
  wait 1.

  maneuver["changePe"](360-math["eccToTrue"](135), newPeri).

  wait 1.
  print BODY:NAME + " landing.".
  landing["parachute"](1).
  TOGGLE AG4.
}
