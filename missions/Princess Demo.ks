{
  local launch is import("lib/launch").

  when ALTITUDE > 55000 THEN {
    TOGGLE AG1.
    when ALTITUDE > 70000 THEN {
      TOGGLE AG2.
    }
  }

  launch["launch"]().

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

}
