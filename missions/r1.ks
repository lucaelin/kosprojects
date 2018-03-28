{
  local launch is import("lib/launch").
  local maneuver is import("lib/maneuver").
  
  when ALTITUDE > 55000 THEN {
    TOGGLE AG1.
    when ALTITUDE > 70000 THEN {
      TOGGLE AG2.
    }
  }

  set MAXSTAGE to STAGE:NUMBER.

  launch["launch"](150000, { return 60. }).

  launch["setStagecontroller"](true).

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

  unlock STEERING.
  SAS on.
}
