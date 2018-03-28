set ASCENDCOMPLETE to false.
lock STEERING to HEADING(90,90).
lock THROTTLE to 1.
set MAXSTAGE to STAGE:NUMBER.
set SAFESTAGE to false.
stage.

WHEN SHIP:VELOCITY:SURFACE:MAG > 100 THEN {
  print "Gravity turn.".
  set turnStartAltitude to ALTITUDE.
  lock STEERING to HEADING(90,90-(90*SQRT((SHIP:ALTITUDE-turnStartAltitude)/(75000-turnStartAltitude)))).
}

WHEN SHIP:MAXTHRUST = 0 or SAFESTAGE = true THEN {
  print "Activating next stage.".
  set SAFESTAGE to false.
  set PRESTAGETHROTTLE to THROTTLE.
  lock THROTTLE to 0.
  if STAGE:READY and STAGE:NUMBER > 0 {
    PRESERVE.
  }

  WHEN true then {
    stage.
    print "STAGE: " + (MAXSTAGE - STAGE:NUMBER).
    lock THROTTLE to PRESTAGETHROTTLE.
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
    set SAFESTAGE to true.
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
KUNIVERSE:TIMEWARP:CANCELWARP().

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
set t to SHIP:ORBIT:PERIOD * (.5 + p).
print "Waiting for " + (.5 + p) + " orbits, " + t + " seconds".
KUNIVERSE:TIMEWARP:WARPTO(TIME:SECONDS + t - 20).
wait t.

print "Transfer burn.".
lock STEERING to PROGRADE.
lock THROTTLE to 1.
wait until APOAPSIS > destination:ALTITUDE / 2.
lock THROTTLE to 0.3.
wait until APOAPSIS > destination:ALTITUDE.
lock THROTTLE to 0.

if MAXSTAGE - STAGE:NUMBER < 4 {
  set SAFESTAGE to true.
}

print "Awaiting SOI.".
wait until SHIP:BODY = destination.
KUNIVERSE:TIMEWARP:CANCELWARP().
wait 10.

print "Adjusting periapsis.".
if PERIAPSIS < 10000 {
  lock STEERING to vcrs(ship:velocity:orbit, vcrs(ship:velocity:orbit,body:position)). // RADIAL OUT
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
KUNIVERSE:TIMEWARP:WARPTO(TIME:SECONDS + ETA:PERIAPSIS - 20).
wait until ETA:PERIAPSIS < 5.

print "Capture burn.".
lock THROTTLE to 1.
wait until APOAPSIS > 0.
wait until APOAPSIS < ALTITUDE*1.5.
lock THROTTLE to 0.

print "Coasting to apoapsis.".
lock STEERING to (-1) * SHIP:VELOCITY:SURFACE.
KUNIVERSE:TIMEWARP:WARPTO(TIME:SECONDS + ETA:APOAPSIS - 20).
wait until ETA:APOAPSIS < 5.
lock THROTTLE to 1.
print "Killing speed.".
wait until VELOCITY:SURFACE:MAG < 5.
lock THROTTLE to 0.

print "Limiting speed to 100.".
until ALT:RADAR < 5000 {
  if VELOCITY:SURFACE:MAG > 100 {
    lock THROTTLE to 1.
  } else {
    lock THROTTLE to 0.
  }
  wait 2.
}

print "Limiting speed to 10.".
until ALT:RADAR < 100 {
  if VELOCITY:SURFACE:MAG > 10 {
    lock THROTTLE to 1.
  } else {
    lock THROTTLE to 0.
  }
  wait 0.5.
}

print "Limiting speed to 5.".
set AG10 to not AG10.
until ALT:RADAR < 1 {
  if VELOCITY:SURFACE:MAG > 5 {
    lock THROTTLE to 1.
  } else {
    lock THROTTLE to 0.
  }
  wait 0.01.
}
lock THROTTLE to 0.

print "Awaiting touchdown.".
wait until SHIP:STATUS = "LANDED".
print "Touchdown.".

print "Mission complete.".
set AG4 to not AG4.
unlock THROTTLE.
unlock STEERING.
SAS on.
