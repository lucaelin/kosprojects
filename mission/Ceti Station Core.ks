{
  local landing is import("lib/landing").
  local launch is import("lib/launch").
  local maneuver is import("lib/maneuver").
  local docking is import("lib/docking").
  local orbit is import("lib/orbit").
  local math is import("lib/math").
  local gui is import("lib/gui").
  local util is import("lib/util").

  local targetBody is BODY("Ceti").

  set TARGET to targetBody.

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

  wait 1.
  until STAGE:NUMBER = 1 {
    wait until STAGE:READY.
    stage.
    wait 1.
  }

  launch["setStagecontroller"](true).

  set TARGET to targetBody.
  print "Targeting " + TARGET:NAME + ".".


  print "Adjusting inclination.".
  maneuver["tgtInclination"]().
  print "Adjusting inclination again.".
  maneuver["tgtInclination"]().
  print "Circularizing again.".
  maneuver["circularize"]().
  print "Transfering to " + TARGET:NAME + ".".
  maneuver["simpleTransfer"](TARGET).

  util["warpTill"]({return SHIP:BODY <> BODY("Kerbin").}, 100000).

  wait 1.
  local targetperi is 1000000.

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
  maneuver["raisePe"](targetperi).
  maneuver["circularize"](true).
  set TARGET to VESSEL("Ceti Station Hab Ship").
  maneuver["tgtInclination"]().
  maneuver["tgtInclination"]().

  maneuver["raisePe"](70000).
  maneuver["circularize"](true).
  maneuver["circularize"]().

  maneuver["simpleTransfer"]().
  docking["rendezvous"]().
  docking["dock"]().
}
