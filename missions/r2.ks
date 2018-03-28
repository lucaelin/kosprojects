{
  local launch is import("lib/launch").
  local maneuver is import("lib/maneuver").
  local docking is import("lib/docking").

  when ALTITUDE > 55000 THEN {
    TOGGLE AG1.
    when ALTITUDE > 70000 THEN {
      TOGGLE AG2.
    }
  }

  set MAXSTAGE to STAGE:NUMBER.

  // set TARGET to Vessel("r1").
  launch["launchTarget"]().
  launch["setStagecontroller"](true).

  print "Adjusting inclination.".
  maneuver["tgtInclination"]().

  print "Circularizing again.".
  maneuver["circularize"]().

  lock STEERING to PROGRADE.
  // <wtf>
  wait 10.
  wait until STAGE:READY.
  stage.
  wait 1.
  wait until STAGE:READY.
  wait 1.
  stage.
  wait until STAGE:READY.
  // </wtf>

  maneuver["simpleTransfer"]().

  docking["rendezvous"]().
  docking["dock"]().
}
