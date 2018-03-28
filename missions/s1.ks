wait 1.
lock STEERING to HEADING(90,80).
lock THROTTLE to 1.
stage.

print "AWAITING ALTITUDE 2700.".
wait until SHIP:ALTITUDE>2000.
lock STEERING to R(0,0,0)+VELOCITY:SURFACE.

print "AWAITING BOOSTER BURNOUT.".
wait until SHIP:MAXTHRUST=0.
wait 0.5.
stage.

print "AWAITING APOAPSIS.".
wait until ETA:APOAPSIS<2.
lock STEERING to HEADING(90,5).
stage.
wait 1.

print "AWAITING FALL.".
wait until VERTICALSPEED<1.
set AG1 to not AG1.

print "AWAITING TOUCHDOWN.".
wait until ALT:RADAR < 1.
wait 5.
set AG1 to not AG1.