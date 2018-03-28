{
  function land {
    parameter vesselHeight is 5.
    parameter maxThrottle is 0.6.
    parameter maxAcc is (SHIP:AVAILABLETHRUST / SHIP:MASS).
    parameter g is (BODY:MU / BODY:RADIUS^2).

    // TODO: body lift might even be stronger than engine thrust, so choose better AoA values.
    print "READ THE TODO!".

    local Kp is 2.0.
    local Ki is 0.01.
    local Kd is 0.1.
    local THRUSTPID is PIDLOOP(Kp, Ki, Kd).
    set THRUSTPID:SETPOINT to 0.

    local turnspeed is 2.
    //TODO: max angle of attack
    local Kp is 1.0/turnspeed.
    local Ki is 0.0/turnspeed.
    local Kd is 1.0/turnspeed.
    local STEERPID is PIDLOOP(Kp, Ki, Kd).
    set STEERPID:SETPOINT to 0.

    //local tgt is LATLNG(8.639955, -168.237632). // VAB E
    local tgt is LATLNG(8.640163554, -168.176736). // PAD
    local tgtheight is tgt:TERRAINHEIGHT. // TODO: make terrainheight optional in case of non target landing
    local maxsteer is SQRT(1-maxThrottle^2)/maxThrottle * 0.9.
    local maxsideacc is (SQRT(1-maxThrottle^2) * maxAcc).
    local twr is maxAcc * maxThrottle / g.

    lock THROTTLE to 0.
    function steer {
      parameter tgtpos is tgt:POSITION.
      parameter AoA is 180. // atm angle of attack
      parameter invert is false. // atm coasting body lift

      CLEARVECDRAWS().
      //CLEARSCREEN.
      VECDRAW(V(0,0,0), tgtpos, white, "tgt", 1, true).
      VECDRAW(V(0,0,0), VELOCITY:SURFACE, red, "vel", 1, true).
      local tgtvel is (VELOCITY:SURFACE:NORMALIZED - SHIP:UP:VECTOR) * VELOCITY:SURFACE:MAG.
      //set tgtvel:MAG to tgt:MAG.
      set tgtpos:MAG to tgtvel:MAG.
      local diff is tgtpos - tgtvel.
      local errsign is SIGN(VDOT(SHIP:UP:VECTOR, diff)).
      set diff to VXCL(SHIP:UP:VECTOR, diff) / (maxsideacc).
      VECDRAW(V(0,0,0), diff, green, "diff", 1, true).
      VECDRAW(V(0,0,0), tgtvel, yellow, "tgtvel", 1, true).
      local error is errsign * diff:MAG.
      //print error at(0, 5).
      set diff:MAG to errsign * CLAMP(-maxsteer, maxsteer, STEERPID:UPDATE(TIME:SECONDS, error)).
      //print diff:MAG at(0, 6).
      //VECDRAW(V(0,0,0), -(SHIP:UP:VECTOR - diff)*ABS(SHIP:VERTICALSPEED), blue, "steer", 1, true).
      //VECDRAW(-(SHIP:UP:VECTOR - diff)*ABS(SHIP:VERTICALSPEED), - 2*SHIP:UP:VECTOR, white, "steer", 1, true).
      local res is (SHIP:UP:VECTOR - diff)*ABS(SHIP:VERTICALSPEED).
      if invert {
        set res to res * ANGLEAXIS(180, SHIP:UP:VECTOR).
      }
      set res to res + 2*SHIP:UP:VECTOR. //stabilize touchdown

      VECDRAW(V(0,0,0), -res, blue, "res", 1, true).

      // limit AoA
      if VANG(SURFACERETROGRADE:VECTOR, res) > AoA {
        set res to SURFACERETROGRADE:VECTOR * ANGLEAXIS(AoA, VCRS(SURFACERETROGRADE:VECTOR, res)).
        VECDRAW(V(0,0,0), res, white, "AoA limited", 1, true).
      }

      return LOOKDIRUP(res, SHIP:FACING:TOPVECTOR).
    }

    function target {
      parameter y is ALTITUDE - tgtheight - vesselHeight.
      parameter maxT is maxThrottle.
      parameter dist is 0.
      parameter speed is 1.

      local acc is maxAcc * maxT - g.
      if acc < 0 {
        print "Error: Not enough thrust to land.".
      }

      return SQRT(2*acc*abs(y - dist) + speed^2).
    }

    wait until SHIP:VERTICALSPEED < 0.
    lock STEERING to steer(tgt:POSITION, 20, true).

    wait until target() < -SHIP:VERTICALSPEED.

    local gearDone is false.
    local thrott is 1.
    lock THROTTLE to thrott.
    lock STEERING to steer(tgt:POSITION, 45).

    until SHIP:VERTICALSPEED >= 0 or SHIP:AVAILABLETHRUST = 0 {
      //CLEARSCREEN.
      //print target() at(0, 0).
      //print -SHIP:VERTICALSPEED at(0, 1).
      //print (target() + SHIP:VERTICALSPEED) / (SHIP:AVAILABLETHRUST / SHIP:MASS) at(0, 2).

      local estTimeRem is -SHIP:VERTICALSPEED / (SHIP:AVAILABLETHRUST * maxThrottle / SHIP:MASS - (BODY:MU / BODY:RADIUS^2)).
      //print estTimeRem at(0, 3).
      if not gearDone and estTimeRem < 5 {
        toggle GEAR.
        set gearDone to true.
      }

      local error is (target() + SHIP:VERTICALSPEED) / (SHIP:AVAILABLETHRUST / SHIP:MASS).
      set thrott to maxThrottle + THRUSTPID:UPDATE(TIME:SECONDS, error).
      wait 0.
    }

    lock THROTTLE to 0.
    lock STEERING to UP.

    wait 0.
  }
  function jebLand {
    print "Coasting to apoapsis.".
    lock STEERING to SURFACERETROGRADE.
    KUNIVERSE:TIMEWARP:WARPTO(TIME:SECONDS + ETA:APOAPSIS - 20).
    wait until ETA:APOAPSIS < 10.
    breakOrbit().

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
    until ALT:RADAR < 5 {
      if VELOCITY:SURFACE:MAG > 5 {
        lock THROTTLE to 1.
      } else {
        lock THROTTLE to 0.
      }
      wait 0.01.
    }
    lock THROTTLE to 0.
    wait 5.
    unlock STEERING.
    unlock THROTTLE.

    print "Awaiting touchdown.".
    wait until SHIP:STATUS = "LANDED".
    print "Touchdown.".
  }
  function breakOrbit {
    print "Breaking orbit.".
    lock STEERING to SURFACERETROGRADE.
    wait 10.
    lock THROTTLE to 1.
    print "Killing speed.".
    wait until VELOCITY:SURFACE:MAG < 5.
    lock THROTTLE to 0.
    wait 0.
  }

  export(lex(
    "land", land@,
    "jebLand", jebLand@,
    "breakOrbit", breakOrbit@
  )).
}
