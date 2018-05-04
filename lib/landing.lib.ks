@lazyglobal off.
{
  function land {
    parameter vesselHeight is 5.
    parameter maxThrottle is 0.6.
    parameter turnspeed is 1. // change orientation in 1 second
    parameter maxAcc is (SHIP:AVAILABLETHRUST / SHIP:MASS).
    parameter g is (BODY:MU / BODY:RADIUS^2).

    local Kp is 1.0.
    local Ki is 0.0.
    local Kd is 1.0.
    local STEERPID is PIDLOOP(Kp, Ki, Kd).
    set STEERPID:SETPOINT to 0.

    //local tgt is LATLNG(8.639955, -168.237632). // VAB E
    //local tgt is LATLNG(8.640163554, -168.176736). // PAD
    //local tgt is TARGET.
    local tgt is VESSEL("landingtest Probe").
    local tgtheight is tgt:ALTITUDE.//VDOT(-SHIP:UP:VECTOR, tgt:POSITION). // TODO: make terrainheight optional in case of non target landing
    local maxsteer is SQRT(1-maxThrottle^2)/maxThrottle * 0.9.
    local maxsideacc is (SQRT(1-maxThrottle^2) * maxAcc).
    local twr is maxAcc * maxThrottle / g.

    lock THROTTLE to 0.
    function steer {
      parameter AoA is 180. // atm angle of attack - negative for atm coasting body lift (inverted steering)

      set invert to false.
      if AoA < 0 {
        set invert to SIGN(AoA) < 0.
        set AoA to ABS(AoA).
      }

      CLEARVECDRAWS().
      CLEARSCREEN.
      local tgtpos is tgt:POSITION.
      local tgtvel is (VELOCITY:SURFACE/2 - SHIP:UP:VECTOR*g*twr).
      VECDRAW(V(0,0,0), tgtpos, white, "tgt", 1, true).
      VECDRAW(V(0,0,0), VELOCITY:SURFACE, red, "vel", 1, true).
      local errsign is SIGN(-VDOT(SHIP:UP:VECTOR, VXCL(tgtpos:NORMALIZED, tgtvel:NORMALIZED))).
      //set tgtvel:MAG to 100.
      set tgtpos:MAG to tgtvel:MAG.
      local diff is tgtpos - tgtvel.
      set diff to VXCL(SHIP:UP:VECTOR, diff).
      VECDRAW(V(0,0,0), diff, green, "error", 1, true).
      VECDRAW(V(0,0,0), tgtvel, yellow, "tgtvel", 1, true).
      local error is errsign * (diff:MAG / turnspeed / maxsideacc)^1.
      print error at(0, 5).
      set diff:MAG to errsign * CLAMP(-maxsteer, maxsteer, STEERPID:UPDATE(TIME:SECONDS, error)).
      VECDRAW(V(0,0,0), diff, rgb(0,255,255), "diffpid*10", 10, true, 0.2/10).
      print diff:MAG at(0, 6).
      //VECDRAW(V(0,0,0), -(SHIP:UP:VECTOR - diff)*ABS(SHIP:VERTICALSPEED), blue, "steer", 1, true).
      //VECDRAW(-(SHIP:UP:VECTOR - diff)*ABS(SHIP:VERTICALSPEED), - 2*SHIP:UP:VECTOR, white, "steer", 1, true).
      local res is (SURFACERETROGRADE:VECTOR - diff)*ABS(SHIP:VERTICALSPEED).
      if invert {
        set res to res * ANGLEAXIS(180, SHIP:UP:VECTOR).
      }
      set res to res + maxsideacc*SHIP:UP:VECTOR. //stabilize touchdown



      VECDRAW(V(0,0,0), -res, blue, "res", 1, true).

      // limit AoA
      if VANG(SURFACERETROGRADE:VECTOR, res) > AoA {
        set res to SURFACERETROGRADE:VECTOR * ANGLEAXIS(AoA, VCRS(SURFACERETROGRADE:VECTOR, res)) * res:MAG.
        VECDRAW(V(0,0,0), -res, white, "AoA limited", 1, true).
      }

      return LOOKDIRUP(res, SHIP:FACING:TOPVECTOR).
    }

    function targetSpeed {
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
    lock STEERING to steer(-20).

    wait until targetSpeed()*1.5 < -SHIP:VERTICALSPEED.

    lock STEERING to steer(30*5*MAX(0,.42-SHIP:Q)).
    // code missing

    lock THROTTLE to 0.
    lock STEERING to UPTOP.

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
