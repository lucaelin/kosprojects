{
  set SHIPNAME to SHIPNAME:SPLIT(" @ ")[0].

  local launch is import("lib/launch").
  local maneuver is import("lib/maneuver").
  local docking is import("lib/docking").

  lock STEERING to PROGRADE.

  print "Adjusting inclination.".
  maneuver["tgtInclination"]().

  print "Circularizing again.".
  maneuver["circularize"]().

  print "Transfer.".
  maneuver["simpleTransfer"]().

  print "Rendezvous.".
  docking["rendezvous"]().

  until STAGE:NUMBER = 0 {
    wait until STAGE:READY.
    stage.
    wait 1.
  }

  wait 1.

  print "Dock.".
  docking["dock"]().


  unlock STEERING.
  unlock THROTTLE.
  TOGGLE AG10.
  SAS on.
}
