wait 1.
lock STEERING to HEADING(90,80).
lock THROTTLE to 1.
stage.

print "AWAITING ALTITUDE 1500.".
wait until SHIP:ALTITUDE>1500.
lock STEERING to R(0,0,0)+VELOCITY:SURFACE.

print "AWAITING BOOSTER BURNOUT.".
wait until SHIP:MAXTHRUST=0.
wait 0.5.
stage.

print "AWAITING APOAPSIS.".
wait until ETA:APOAPSIS<20.
set AG1 to not AG1.
lock STEERING to HEADING(90,5).
stage.
wait 1.

print "AWAITING DESTINATION ORBIT.".
wait until APOAPSIS > 350000.
lock THROTTLE to 0.

print "AWAITING APOAPSIS AGAIN.".
wait until ETA:APOAPSIS<5.
set AG2 to not AG2.