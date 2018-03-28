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

print "Coasting to equator.".
if SHIP:GEOPOSITION:LAT > 0 {
  lock STEERING to vcrs(ship:velocity:orbit,-body:position). // NORMAL
  wait until SHIP:GEOPOSITION:LAT < 0.
} else {
  lock STEERING to vcrs(-ship:velocity:orbit,-body:position). // ANTINORMAL
  wait until SHIP:GEOPOSITION:LAT < 0.
}

print "Burning for minimal inclination.".
lock THROTTLE to 1.
set dist to SHIP:ORBIT:INCLINATION.
wait until SHIP:ORBIT:INCLINATION < dist.
set diff to dist - SHIP:ORBIT:INCLINATION.
until SHIP:ORBIT:INCLINATION - dist > 0 {
  set dist to SHIP:ORBIT:INCLINATION.
}
lock THROTTLE to 0.

print "Mission objective.".
lock STEERING to PROGRADE.
set TARGET to BODY("Iota").

print "Waiting for target to become closest.".
set destination to TARGET.
set dist to destination:POSITION:MAG.
wait until destination:POSITION:MAG < dist.
set diff to dist - destination:POSITION:MAG.
until destination:POSITION:MAG - dist > 0 {
  set dist to destination:POSITION:MAG.
  wait 0.5.
}

print "Preparing Transfer.".
set s to SHIP:ORBIT:SEMIMAJORAXIS.
set d to destination:ORBIT:SEMIMAJORAXIS.
set h to (s+d)/2.
set p to 1 / (2 * SQRT(d^3 / h^3)).
print "Waiting for " + (.5 + p) + "orbits.".
wait SHIP:ORBIT:PERIOD * (.5 + p).

print "Transfer burn.".
lock STEERING to PROGRADE.
lock THROTTLE to 1.
wait until APOAPSIS > destination:ALTITUDE.
lock THROTTLE to 0.

print "Awaiting SOI.".
wait until SHIP:BODY = destination.

print "Adjusting periapsis.".
if PERIAPSIS < 10000 {
  lock STEERING to vcrs(ship:velocity:orbit, vcrs(ship:velocity:orbit,-body:position)). // RADIAL IN
  wait 10.
  lock THROTTLE to 0.5.
  wait until PERIAPSIS > 10000.
} else {
  lock STEERING to RETROGRADE.
  wait 10.
  lock THROTTLE to 0.5.
  wait until PERIAPSIS < 10000.
}
lock THROTTLE to 0.

print "Coasting to periapsis.".
lock STEERING to RETROGRADE.
wait until ETA:PERIAPSIS < 5.
set AG4 to not AG4.
lock THROTTLE to 1.
wait until APOAPSIS < ALTITUDE * 5.
lock THROTTLE to 0.

print "Coasting to apoapsis.".
wait until ETA:APOAPSIS < 5.
set AG4 to not AG4.

print "Mission complete.".