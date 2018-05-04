{
  local launch is import("lib/launch").
  //local landing is import("lib/landing").
  local control is import("lib/control").

  //toggle GEAR.
  toggle AG1.
  launch["verticalAscend"](300, 1.0).
  //stage.
  //wait 1.
  //control["vspeed"]({
  //  print 100*SHIP:CONTROL:PILOTMAINTHROTTLE at(0,20).
  //  return (100*SHIP:CONTROL:PILOTMAINTHROTTLE-ALT:RADAR) / 5.
  //}).

  local maxThrottle is 0.5.
  local maxAcc is (SHIP:AVAILABLETHRUST / SHIP:MASS).
  local g is (BODY:MU / BODY:RADIUS^2).
  local vesselHeight is 1.3.
  local tgt is VESSEL(SHIPNAME + " Probe").
  local tgtheight is tgt:ALTITUDE.//VDOT(-SHIP:UP:VECTOR, tgt:POSITION). // TODO: make terrainheight optional in case of non target landing
  local maxsteer is SQRT(1-maxThrottle^2)/maxThrottle * 0.9.
  local maxsideacc is (SQRT(1-maxThrottle^2) * maxAcc).
  print maxsideacc.
  local twr is maxAcc * maxThrottle / g.
  function targetSpeed {
    parameter y is ALTITUDE - tgtheight - vesselHeight.
    parameter maxT is maxThrottle.
    parameter dist is 0. //VXCL(SHIP:UP:VECTOR, tgt:POSITION):MAG.
    parameter speed is 1.

    local acc is maxAcc * maxT - g.
    if acc < 0 {
      print "Error: Not enough thrust to land.".
    }

    local sig is -SIGN(y - dist).
    return sig * SQRT(2*acc*abs(y - dist) + speed^2).
  }
  control["vspeed"](targetspeed@, 10).

  //control["hspeed"]({
  //  return -SHIP:CONTROL:PILOTYAW * VCRS(SHIP:UP:VECTOR, SHIP:NORTH:VECTOR):NORMALIZED * 50
  //    + SHIP:CONTROL:PILOTPITCH * SHIP:NORTH:VECTOR * 50.
  //}).
  set STEERINGMANAGER:MAXSTOPPINGTIME to 10.
  //set STEERINGMANAGER:PITCHPID:KP to 5.
  //set STEERINGMANAGER:YAWPID:KP to 5.
  //set STEERINGMANAGER:PITCHPID:KD to 0.1.
  //set STEERINGMANAGER:YAWPID:KD to 0.1.
  local hacc is 5.
  //local Kp is 0.4.
  //local Ki is 0.
  //local Kd is 0.2.
  local Klimit is maxsideacc / 3.
  local lookahead is 1.
  local Kp is 3.
  local Ki is 0.
  local Kd is 0.

  control["hspeed"]({
    local dist is VXCL(SHIP:UP:VECTOR, tgt:POSITION - SHIP:VELOCITY:SURFACE * lookahead).
    local accf is SQRT(2*hacc*MAX(0,dist:MAG-10)).
    if accf > 5 return dist:NORMALIZED * accf.
    return dist:NORMALIZED * dist:MAG/2.
  }, maxThrottle, lookahead, Klimit, Kp, Ki, Kd).


  wait until false.
}
