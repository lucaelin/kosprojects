wait 1.
lock STEERING to UP.
lock THROTTLE to 1.
stage.

print "AWAITING SPEED 100.".
wait until SHIP:VELOCITY:SURFACE:MAG>100.
lock STEERING to HEADING(0,90-(90*SQRT(SHIP:ALTITUDE/75000))).

print "AWAITING PAYLOAD DEPLOY.".
wait until SHIP:MAXTHRUST=0.
wait until ALTITUDE>55000.
wait 0.5.
stage.

print "AWAITING APOAPSIS.".
wait until ETA:APOAPSIS<20.
set AG1 to not AG1.
lock STEERING to HEADING(0,5).
wait 1.
stage.

print "AWAITING DESTINATION ORBIT.".
wait until PERIAPSIS > 75000.
lock THROTTLE to 0.

set AG2 to not AG2.
