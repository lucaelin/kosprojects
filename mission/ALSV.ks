{
  local landing is import("lib/landing").
  local maneuver is import("lib/maneuver").
  local docking is import("lib/docking").
  local orbit is import("lib/orbit").

  set TARGET to VESSEL("Desire Station").
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

  print "Circularizing.".
  maneuver["circularize"]().

  set TARGET to VESSEL("Desire Station").
  wait 1.

  print "Adjusting inclination.".
  maneuver["tgtInclination"]().

  print "Circularizing again.".
  maneuver["circularize"]().

  until STAGE:NUMBER = 1 {
    wait until STAGE:READY.
    stage.
    wait 1.
  }

  print "Transfer.".
  maneuver["simpleTransfer"]().

  print "Rendezvous.".
  docking["rendezvous"]().

  print "Dock.".
  docking["dock"]().

  print "Waiting to undock.".
  docking["undock"](VESSEL("Desire Station")).

  print "Deorbit.".
  maneuver["raisePe"](30000).

  lock STEERING to SURFACERETROGRADE.

  wait until ALT:RADAR < 9000.

  local tgt is "somewhere".
  local thrott is 0.6.
  local height is 2.0.
  local AoA is 45.
  local hThrott is 0.5.
  local lookahead is 0.8.
  local bodylift is true.
  local ttiMult is 0.0.

  landing["land"](tgt, thrott, height, AoA, hThrott, lookahead, bodylift, ttiMult).

  lock STEERING to UPTOP.
  wait until false.
}
