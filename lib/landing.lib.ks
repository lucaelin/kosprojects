@lazyglobal off.
{
  local control is import("lib/control").
  local math is import("lib/math").
  local orbit is import("lib/orbit").

  //*
  //* function to propulsively land at a given place.
  //* parameter tgt the target to land at. Can be a Vessel, GeoCoordinate or a String if i should just land somewhere
  //* more parameters explained in the function itself
  //*
  function land {
    parameter tgt.
    parameter vThrottle is 0.6. // use max 0.6 of the available thrust for vertical deceleration
    parameter vesselHeight is 5. // account for the offset between the ships lowest point and its CoM
    parameter AoA is 90. // tile the ship max 90° off its vertical position
    parameter hThrottle is 0.5. // break horizontally with 0.5 of the maximal horizontal deceleration
    parameter lookahead is 0.8. // predict the vessels orientation 0.8 seconds ahead to match the sterring
    parameter bodylift is false. // invert the steering while the engines are sill deactivated
    parameter ttiMult is 0. // multiply the tti by this value to account for atm drag

    local done is false.

    // v controls
    local maxAcc is (SHIP:AVAILABLETHRUST / SHIP:MASS).
    local g is (BODY:MU / BODY:RADIUS^2).
    local twr is maxAcc * vThrottle / g.
    local vKp is 10.

    // h controls
    local maxAoA is ARCCOS(vThrottle).
    set AoA to MIN(AoA, maxAoA).
    local maxSideAcc is (maxAcc * vThrottle) * TAN(AoA).
    local hacc is maxSideAcc * hThrottle.
    local Klimit is maxSideAcc.
    local hKp is 10.
    local tgtheight is 0.
    if tgt:TYPENAME = "Vessel" {
      set tgtheight to tgt:GEOPOSITION:TERRAINHEIGHT.
    } else if tgt:TYPENAME = "GeoCoordinates" {
      set tgtheight to tgt:TERRAINHEIGHT.
    } else if tgt:TYPENAME = "String" {
      set tgtHeight to SHIP:GEOPOSITION:TERRAINHEIGHT.
    } else {
      print "Unknown typename of tgt. Abort.".
      return.
    }
    local lock y to ALTITUDE - tgtheight - vesselHeight.

    control["vSpeed"]({
      parameter speed is 0.1.

      CLEARSCREEN.

      print "    distance: " + y at(0,2).
      print "timeToImpact: " + getTimeToImpact(y) at(0,3).
      print " impactSpeed: " + getSpeed(y) at(0,4).
      print "burnDuration: " + getBurnDuration(vThrottle, y) at(0,5).
      print "  timeToBurn: " + getTimeToBurn(vThrottle, y) at(0,6).
      print "  timeToLand: " + getTimeToLand(vThrottle, y) at(0,7).
      print "  timeAtLand: " + (TIME:SECONDS + getTimeToLand(vThrottle, y)) at(0,8).
      print "        time: " + TIME:SECONDS at(0,9).

      local acc is maxAcc * vThrottle - g.
      if acc < 0 {
        print "Error: Not enough thrust to land.".
      }
      if SHIP:VERTICALSPEED > -speed and y < 0 {
        control["disableVSpeed"]().
        control["disableHSpeed"]().
        set done to true.
        return -speed.
      }

      local sig is -SIGN(y).
      return sig * SQRT(2*acc*abs(MIN(y,ALT:RADAR)) - speed^2).
    }, vKp).


    //control["hSpeed"]({
    //  local tgtpos is tgt:POSITION + tgt:VELOCITY:SURFACE * getTimeToLand(vThrottle).
    //  VECDRAW(V(0,0,0), tgtpos, white, "tgt", 1, true, 0.2).
    //  local dist is VXCL(SHIP:UP:VECTOR, tgtpos - SHIP:VELOCITY:SURFACE * lookahead).//(getTimeToLand(vThrottle))).
    //  local tvel is SQRT(2*hacc*MAX(0,dist:MAG-4)).
    //  local tvelLin is dist:MAG / 1.5.

    //  if dist:MAG > 10 return dist:NORMALIZED * tvel.
    //  return dist:NORMALIZED * MAX(tvel, tvelLin).
    //}, vThrottle, lookahead, Klimit, hKp).
    control["hSpeed"]({
      local tgtpos is V(0,0,0).
      if tgt:TYPENAME = "String" {
        return BODY:POSITION.
      } else {
        set tgtpos to (tgt:POSITION - getBurnPosition(vThrottle, y)) + tgt:VELOCITY:SURFACE * getTimeToLand(vThrottle).
      }
      VECDRAW(V(0,0,0), tgtpos, white, "tgt", 1, true, 0.2).
      local dist is VXCL(SHIP:UP:VECTOR, tgtpos - getBurnVelocity(vThrottle, y) * lookahead).
      local tvel is SQRT(2*hacc*MAX(0,dist:MAG-4)).
      local tvelLin is dist:MAG / 1.5.

      VECDRAW(V(0,0,0), getBurnPosition(vThrottle, y), blue, "burnPos", 1, true, 1).
      VECDRAW(V(0,0,0), getBurnVelocity(vThrottle, y), yellow, "burnVel", 1, true, 0.2).
      VECDRAW(V(0,0,0), SHIP:VELOCITY:SURFACE, red, "vel", 1, true, 0.2).

      if dist:MAG > 10 return dist:NORMALIZED * tvel.
      return dist:NORMALIZED * MAX(tvel, tvelLin).
    }, vThrottle, lookahead, Klimit, hKp).

    if bodylift {
      on THROTTLE {
        control["hSpeedInvert"](THROTTLE = 0).
        if not done {PRESERVE.}
      }
      control["hSpeedInvert"](THROTTLE = 0).
    }

    wait until done.
  }

  //*
  //* primitive function to land using multiple speedsteps during descent and hysteresis to control the speed
  //*
  function jebLand {
    print "Coasting to apoapsis.".
    lock STEERING to SURFACERETROGRADE.
    KUNIVERSE:TIMEWARP:WARPTO(TIME:SECONDS + ETA:APOAPSIS - 20).
    wait until ETA:APOAPSIS < 10.
    breakOrbit().

    print "Limiting speed to 100.".
    until ALT:RADAR < 5000 {SQRT(2*acc*abs(y - dist) + speed^2).
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

  //*
  //* primitive function to kill (almost) all horizontal speed
  //*
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

  //*
  //* primitive function to land using parachutes
  //* does not suit any situation
  //*
  function parachute {
    parameter stagenr is 0.
    parameter chutedub is "chute".

    lock STEERING to RADIALIN.
    local warptime is TIME:SECONDS + orbit["timeToTrue"](360-math["trueAtRadius"](BODY:RADIUS + BODY:ATM:HEIGHT * 1.5)).
    KUNIVERSE:TIMEWARP:WARPTO(warptime).
    wait until TIME:SECONDS > warptime.
    wait until KUNIVERSE:TIMEWARP:ISSETTLED.

    wait 5.

    until STAGE:NUMBER = stagenr {
      wait until STAGE:READY.
      stage.
      wait 1.
    }
    PANELS off.


    wait until SHIP:ALTITUDE < SHIP:BODY:ATM:HEIGHT.
    lock STEERING to SURFACERETROGRADE.

    wait until SHIP:VELOCITY:SURFACE:MAG < 1000.
    for p in SHIP:PARTS {
      for m in p:MODULES {
        if m:TOLOWER:CONTAINS(chutedub) {
          set m to p:GETMODULE(m).
          for a in m:ALLACTIONNAMES {
            if a:TOLOWER:CONTAINS("arm") and not a:TOLOWER:CONTAINS("disarm") {
              print a.
              m:DOACTION(a, true).
            }
          }
        }
      }
    }
    wait until SHIP:VELOCITY:SURFACE:MAG < 200.
    unlock STEERING.
    wait until SHIP:STATUS = "LANDED" or SHIP:STATUS = "SPLASHED".
  }

  function getA {
    local g is BODY:MU/BODY:RADIUS^2.
    return g - ((SHIP:ORBIT:VELOCITY:ORBIT:SQRMAGNITUDE - SHIP:VERTICALSPEED^2)/(BODY:RADIUS)).
  }
  function getTimeToImpact {
    parameter y is ALT:RADAR.
    // x = v*t + 1/2 * a * t^2
    // t = (-v + sqrt(v^2 + 2 * a * h))/a
    local a is getA().
    if y < 0 { return 0. }.

    return (SHIP:VERTICALSPEED + SQRT(SHIP:VERTICALSPEED^2 + 2 * a * y)) / a.
  }
  function getSpeed {
    parameter y is ALT:RADAR.
    parameter t is getTimeToImpact(y).

    local a is getA().

    // v = v0 + a * t
    return -SHIP:VERTICALSPEED + a * t.
  }
  function getBurnDuration {
    parameter throt is 1.
    parameter y is ALT:RADAR.

    // gravitational acc not needed because its already in the impactSpeed
    // (though due to the extended descend it would need to be added again by some factor)
    local dec is throt * SHIP:AVAILABLETHRUST / SHIP:MASS.

    return getSpeed(y) / dec.
  }
  function getTimeToLand {
    parameter throt is 1.
    parameter y is ALT:RADAR.

    local tti is getTimeToImpact(y).
    local ttl is tti + getBurnDuration(throt, y)/2.
    return ttl.
  }
  function getTimeToBurn {
    parameter throt is 1.
    parameter y is ALT:RADAR.

    local tti is getTimeToImpact(y).
    local ttl is tti - getBurnDuration(throt, y)/2.
    return ttl.
  }
  function getBurnPosition {
    parameter throt is 1.
    parameter y is ALT:RADAR.

    return (SHIP:VELOCITY:SURFACE + 0.5 * getA() * (-SHIP:UP:VECTOR)) * getTimeToBurn(throt, y).
  }
  function getBurnVelocity {
    parameter throt is 1.
    parameter y is ALT:RADAR.

    return SHIP:VELOCITY:SURFACE + getA() * (-SHIP:UP:VECTOR) * getTimeToBurn(throt, y).
  }

  export(lex(
    "land", land@,
    "jebLand", jebLand@,
    "breakOrbit", breakOrbit@,
    "parachute", parachute@
  )).
}
