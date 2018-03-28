wait 1.
lock STEERING to HEADING(90,80).
lock THROTTLE to 1.
stage.

print "AWAITING ALTITUDE 1200.".
wait until SHIP:ALTITUDE>1200.
lock STEERING to R(0,0,0)+VELOCITY:SURFACE.

print "AWAITING BOOSTER BURNOUT.".
wait until SHIP:MAXTHRUST=0.
wait 0.5.
stage.

print "AWAITING APOAPSIS.".
wait until ETA:APOAPSIS<20.
lock STEERING to HEADING(90,5).
stage.
wait 1.

print "AWAITING STABLE ORBIT.".
wait until PERIAPSIS > 75000.
lock THROTTLE to 0.

print "AWAITING APOAPSIS AGAIN.".
wait until ETA:APOAPSIS<5.
lock STEERING to RETROGRADE.
wait 1.
lock THROTTLE to 0.5.

print "AWAITING DEORBIT.".
wait until PERIAPSIS < 35000.
lock THROTTLE to 0.

print "AWAITING CHUTE.".
wait until ALT:RADAR < 15000.
stage.