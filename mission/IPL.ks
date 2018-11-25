{
  local landing is import("lib/landing").
  local launch is import("lib/launch").
  local maneuver is import("lib/maneuver").
  local docking is import("lib/docking").
  local orbit is import("lib/orbit").
  local math is import("lib/math").
  local gui is import("lib/gui").
  local util is import("lib/util").

  local targetBody is BODY("Tellumo").

  set TARGET to targetBody.

  maneuver["simpleTransfer"](TARGET, BODY("Kerbin"), true).
  maneuver["simpleTransfer"](TARGET, BODY("Kerbin"), true).

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

  set TARGET to targetBody.
  print "Targeting " + TARGET:NAME + ".".


  print "Adjusting inclination.".
  maneuver["tgtInclination"]().
  print "Circularizing again.".
  maneuver["circularize"]().
  print "Transfering to " + TARGET:NAME + ".".
  maneuver["simpleTransfer"](TARGET, BODY("Kerbin")).

  util["warpTill"]({return SHIP:BODY <> BODY("Kerbin").}, 10000).

  print "Adjusting inclination.".
  maneuver["tgtInclination"](TARGET).

  util["warpTill"]({return SHIP:BODY = targetBody.}, 100000).

  wait 1.

  local targetperi is 150000.

  print "Adjusting periapsis.".
  if PERIAPSIS > targetperi {
    lock STEERING to RETROGRADE.
    wait 10.
    lock THROTTLE to 1.
    wait until PERIAPSIS < targetperi * 2.
    lock THROTTLE to 0.1.
    wait until PERIAPSIS < targetperi.
    lock THROTTLE to 0.
  }
  lock STEERING to RADIALOUT.
  wait 10.
  lock THROTTLE to 1.
  wait until PERIAPSIS > 0.
  lock THROTTLE to 0.1.
  wait until PERIAPSIS > targetperi.
  lock THROTTLE to 0.

  print BODY:NAME + " orbit insertion.".
  maneuver["capture"]().
  maneuver["polarize"]().
  maneuver["raiseAp"](2000000).
  maneuver["raisePe"](25000).
  when ALTITUDE < BODY:ATM:HEIGHT * 2 THEN {
    TOGGLE AG4.
  }
  landing["parachute"]().

  TOGGLE AG5.
}
