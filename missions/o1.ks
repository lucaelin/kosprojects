set ASCENDCOMPLETE to false.
lock STEERING to UP.
lock THROTTLE to 1.
stage.

WHEN SHIP:VELOCITY:SURFACE:MAG > 100 THEN {
  print "Gravity turn.".
  set turnStartAltitude to ALTITUDE.
  lock STEERING to HEADING(90,90-(90*SQRT((SHIP:ALTITUDE-turnStartAltitude)/(75000-turnStartAltitude)))).
}

WHEN SHIP:MAXTHRUST = 0 THEN {
  print "Engine burnout.".
  lock THROTTLE to 0.
  stage.
  wait 1.
  lock THROTTLE to 1.
  IF STAGE:READY {
    PRESERVE.
  }
}
WHEN ALTITUDE > 55000 THEN {
  print "Jettison fairing.".
  set AG1 to not AG1.

  WHEN ALTITUDE > 70000 THEN {
    print "Deploying Antennae and Panels.".
    set AG2 to not AG2.
  }
}
WHEN APOAPSIS > 85000 THEN {
  print "Ascend complete.".
  lock THROTTLE to 0.

  WHEN ALTITUDE > 70000 THEN {
    lock STEERING to HEADING(90,0).

    set v1 to SQRT(BODY:MU*((2/APOAPSIS)-(1/ORBIT:SEMIMAJORAXIS))).
    set v2 to SQRT(BODY:MU*((2/APOAPSIS)-(1/APOAPSIS))).
    set cirDV to v2-v1.
    set accel to SHIP:MAXTHRUST/SHIP:MASS. // careful with staging!
    set burntime to cirDV / accel.
    print "Circularization dV: "+cirDV.
      
    WHEN ETA:APOAPSIS < (burntime / 2) THEN {
      print "Starting circularization.".
      lock THROTTLE to 1.
      set shutdownTime to TIME:SECONDS + burntime.
      WHEN TIME:SECONDS > shutdownTime THEN {
        print "Finished circularization.".
        lock THROTTLE to 0.
        set ASCENDCOMPLETE to true.
      }
    }
  }
}

wait until ASCENDCOMPLETE.
set AG3 to not AG3.
lock STEERING to RETROGRADE.
wait 10.
lock THROTTLE to 1.
wait until PERIAPSIS < 35000.
lock THROTTLE to 0.
wait 0.
stage.
stage.
stage.