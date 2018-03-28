set ASCENDCOMPLETE to false.
lock STEERING to HEADING(90,90).
lock THROTTLE to 1.
set MAXSTAGE to STAGE:NUMBER.
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
  print "STAGE: " + (MAXSTAGE - STAGE:NUMBER).
  lock THROTTLE to 1.
  if STAGE:READY and STAGE:NUMBER > 0 {
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
  print "STAGE: " + (MAXSTAGE - STAGE:NUMBER).
  if MAXSTAGE - STAGE:NUMBER < 3 {
    stage.
  }

  WHEN ALTITUDE > 70000 THEN {
    lock STEERING to HEADING(90,0).

    set r to APOAPSIS + BODY:RADIUS.
    set v1 to SQRT(BODY:MU*((2/r)-(1/ORBIT:SEMIMAJORAXIS))).
    set v2 to SQRT(BODY:MU*((2/r)-(1/r))).
    set cirDV to v2 - v1.
    set accel to SHIP:MAXTHRUST/SHIP:MASS. // careful with staging!
    set burntime to cirDV / accel.
    print "Circularization dV: "+cirDV.
      
    WHEN ETA:APOAPSIS < (burntime / 2) THEN {
      print "Starting circularization.".
      lock THROTTLE to 1.
      set shutdownSpeed to SHIP:VELOCITY:ORBIT:MAG + cirDV.
      // set shutdownTime to TIME:SECONDS + burntime.
      WHEN SHIP:VELOCITY:ORBIT:MAG > shutdownSpeed THEN {
        print "Finished circularization.".
        lock THROTTLE to 0.
        set ASCENDCOMPLETE to true.
      }
    }
  }
}

wait until ASCENDCOMPLETE.
set AG3 to not AG3.

print "Mission objective.".
wait 60*60*5.

print "Coasting to periapsis.".
lock STEERING to RETROGRADE.
wait until ETA:PERIAPSIS < 5.

print "Deorbit.".
lock THROTTLE to 0.5.
wait until PERIAPSIS < 35000.
lock THROTTLE to 0.

print "Awaiting reenty.".
wait until ALTITUDE < 70000.
set AG10 to not AG10.
until STAGE:NUMBER = 0 {
  if STAGE:READY {
    stage.
  }
}

print "Awaiting landing.".
wait until SHIP:VELOCITY:SURFACE:MAG < 500.
lock STEERING to HEADING(90, 90).
wait until SHIP:STATUS = "LANDED".
print "Mission complete.".