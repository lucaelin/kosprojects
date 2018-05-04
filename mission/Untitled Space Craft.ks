{
  local launch is import("lib/launch").
  //local landing is import("lib/landing").
  local control is import("lib/control").

  //toggle GEAR.
  toggle AG1.
  launch["verticalAscend"](300, 1).
  //control["vspeed"]({
  //  print 100*SHIP:CONTROL:PILOTMAINTHROTTLE at(0,20).
  //  return (100*SHIP:CONTROL:PILOTMAINTHROTTLE-ALT:RADAR) / 5.
  //}).

  local maxThrottle is 0.1.
  local maxAcc is (SHIP:AVAILABLETHRUST / SHIP:MASS).
  local g is (BODY:MU / BODY:RADIUS^2).
  local vesselHeight is 2.
  local tgt is VESSEL(SHIPNAME + " Probe").
  local tgtheight is tgt:ALTITUDE.//VDOT(-SHIP:UP:VECTOR, tgt:POSITION). // TODO: make terrainheight optional in case of non target landing
  local maxsteer is SQRT(1-maxThrottle^2)/maxThrottle * 0.9.
  local maxsideacc is (SQRT(1-maxThrottle^2) * maxAcc).
  local twr is maxAcc * maxThrottle / g.
  function targetSpeed {
    parameter y is ALTITUDE - tgtheight - vesselHeight.
    parameter maxT is maxThrottle.
    parameter dist is 0.
    parameter speed is 1.

    local acc is maxAcc * maxT - g.
    if acc < 0 {
      print "Error: Not enough thrust to land.".
    }

    local sig is -SIGN(y - dist).
    return sig * SQRT(2*acc*abs(y - dist) + speed^2).
  }
  control["vspeed"](targetspeed@).

  //control["hspeed"]({
  //  return -SHIP:CONTROL:PILOTYAW * VCRS(SHIP:UP:VECTOR, SHIP:NORTH:VECTOR):NORMALIZED * 50
  //    + SHIP:CONTROL:PILOTPITCH * SHIP:NORTH:VECTOR * 50.
  //}).
  set STEERINGMANAGER:MAXSTOPPINGTIME to 10.
  //set STEERINGMANAGER:PITCHPID:KP to 5.
  //set STEERINGMANAGER:YAWPID:KP to 5.
  //set STEERINGMANAGER:PITCHPID:KD to 0.1.
  //set STEERINGMANAGER:YAWPID:KD to 0.1.
  local hacc is 6.
  //local Kp is 0.25.
  //local Ki is 0.
  //local Kd is 0.50.
  local Klimit is 20.
  local Kp is 0.6.
  local Ki is 0.
  local Kd is 0.4.

  control["hspeed"]({
    local dist is VXCL(SHIP:UP:VECTOR, tgt:POSITION - SHIP:VELOCITY:SURFACE).
    return dist:NORMALIZED * MAX(dist:MAG/2,SQRT(2*hacc*MAX(0,dist:MAG-5))).
  }, Kp, Ki, Kd, Klimit).

  wait until false.
}
