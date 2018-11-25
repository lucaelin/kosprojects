@lazyglobal off.
{
  local control is import("lib/control").
  local math is import("lib/math").
  local orbit is import("lib/orbit").
  local gui is import("lib/gui").

  //*
  //* function to propulsively land at a given place.
  //* parameter tgt the target to land at. Can be a Vessel, GeoCoordinate or a String if i should just land somewhere
  //* more parameters explained in the function itself
  //*
  function land {
    parameter tgt is "somewhere".
    parameter vThrottle is 0.8. // use max 0.6 of the available thrust for vertical deceleration
    parameter vesselHeight is 5. // account for the offset between the ships lowest point and its CoM
    parameter AoA is 60. // tile the ship max 60° off its vertical position
    parameter hThrottle is 0.5. // break horizontally with 0.5 of the maximal horizontal deceleration
    parameter lookahead is 0.8. // predict the vessels orientation 0.8 seconds ahead to match the steering
    parameter bodylift is false. // invert the steering while the engines are sill deactivated
    parameter ttiMult is 1. // multiply the tti by this value to account for atm drag TODO enable

    local done is false.
    local guiCtx is gui["createContext"]("landing").
    local logGui is guiCtx["log"].
    local vecGui is guiCtx["vec"].

    //if SHIP:VERTICALSPEED > 0 {
    //  warn("Awaiting descend.").
    //  wait until SHIP:VERTICALSPEED < 0.
    //}

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

    local impact is SHIP:GEOPOSITION.
    {
      local idist is 1.
      until idist < 1 {
        local ypredict is ALTITUDE - MAX(0, impact:TERRAINHEIGHT).
        local burnPos is getBurnPosition(vThrottle, ypredict).
        local burnVel is getBurnVelocity(vThrottle, ypredict).
        local ttl is getTimeToLand(vThrottle, ypredict).
        local hVel is VXCL(SHIP:UP:VECTOR, burnVel).
        local hStopTime is hVel:MAG / hacc.
        if not bodyLift and hStopTime > getBurnDuration(vThrottle, ypredict) * 0.8 {
          gui["error"]("Unable to kill horizontal velocity in time!").
          set vThrottle to findBurnThottle(hStopTime * 1.5, ypredict).
          gui["show"]("Adjusted vThrottle to "+vThrottle).
        }

        local hStopDist is 0.5 * hVel * hStopTime.
        local impactVec is burnPos + hStopDist.
        local impactGeo is BODY:GEOPOSITIONOF(impactVec).
        local impactGeoPos is impactGeo:ALTITUDEPOSITION(MAX(0, impactGeo:TERRAINHEIGHT)).
        local impactPos is impact:ALTITUDEPOSITION(MAX(0, impact:TERRAINHEIGHT)).
        set idist to (impactGeoPos - impactPos):MAG.
        print idist.
        set impact to impactGeo.
      }
    }
    if bodylift {
      set impact to BODY:GEOPOSITIONOF(impact:POSITION/2).
    }

    // automatic landing prediction
    if tgt:TYPENAME = "Scalar" {
      set maxslope to tgt.
      set tgt to impact.
      local slope is 180.
      local down is V(0,0,0).
      until slope < maxslope {
        print "slope: " + slope.
        set tgt to BODY:GEOPOSITIONOF(tgt:POSITION + down).
        local localup is (tgt:POSITION - BODY:POSITION):NORMALIZED.
        local pos is BODY:GEOPOSITIONOF(tgt:POSITION - SHIP:NORTH:VECTOR - VCRS(localup, SHIP:NORTH:VECTOR)):POSITION.
        local posN is BODY:GEOPOSITIONOF(pos + SHIP:NORTH:VECTOR * SQRT(2)):POSITION.
        local posE is BODY:GEOPOSITIONOF(pos + VCRS(localup, SHIP:NORTH:VECTOR * SQRT(2))):POSITION.
        local n is VCRS(posN - pos, posE - pos):NORMALIZED.
        set down to (n - localup):NORMALIZED.
        set slope to VANG(localup, n).

        vecGui("tgt", tgt:POSITION, white).
        vecGui("n", n*10, green).
        vecGui("u", SHIP:UP:VECTOR*10, blue).
        wait 0.
      }
      print "downrange: "+ (impact:POSITION - tgt:POSITION):MAG.
    }
    if tgt:TYPENAME = "String" {
      set tgt to impact.
    }

    local tgtPos is { return V(0,0,0). }.
    local tgtheight is { return 0. }.
    if tgt:TYPENAME = "Vessel" {
      set tgtPos to { return tgt:POSITION. }.
      set tgtheight to { return tgt:ALTITUDE. }.
    } else if tgt:TYPENAME = "GeoCoordinates" {
      set tgtPos to { return tgt:ALTITUDEPOSITION(MAX(0, tgt:TERRAINHEIGHT)). }.
      set tgtheight to { return MAX(0, tgt:TERRAINHEIGHT). }.
    } else {
      print "Unknown typename of tgt. Abort.".
      return.
    }
    local lock y to ALTITUDE - tgtheight() - vesselHeight.

    if not bodylift {
      // pre landing adjustment
      local diff is tgtPos() - impact:ALTITUDEPOSITION(MAX(0, impact:TERRAINHEIGHT)).
      local tRem is getTimeToBurn(vThrottle, y) - 5.
      local deltaSpeed is diff / tRem.

      lock STEERING to deltaSpeed.
      wait 8.
      lock THROTTLE to 0.5.
      wait deltaSpeed:MAG / (maxAcc * 0.5).
      lock THROTTLE to 0.
      lock STEERING to UPTOP.
      wait 3.
    }

    control["vSpeed"]({
      parameter speed is 0.1.

      logGui("timeToBurn", getTimeToBurn(vThrottle, y), "s").
      logGui("timeToLand", getTimeToLand(vThrottle, y), "s").
      logGui("timeToImpact", getTimeToImpact(y), "s").
      logGui("burnDuration", getBurnDuration(vThrottle, y), "s").
      logGui("veticalBurnVel", getSpeed(y), "m/s").
      logGui("horizontalBurnVel", VXCL(SHIP:UP:VECTOR, getBurnVelocity(vThrottle, y)):MAG, "m/s").

      local acc is maxAcc * vThrottle - g.
      if acc < 0 {
        print "Error: Not enough thrust to land (" + acc + ").".
      }
      if (SHIP:VERTICALSPEED > -speed and y < 0) or SHIP:STATUS = "LANDED" {
        control["disableVSpeed"]().
        control["disableHSpeed"]().
        set done to true.
        return -speed.
      }

      local sig is -SIGN(y).
      return sig * SQRT(2*acc*abs(MIN(y,ALT:RADAR)) - speed^2).
    }, vKp).

    control["hSpeed"]({
      local burnPos is getBurnPosition(vThrottle, y).
      local burnVel is getBurnVelocity(vThrottle, y).

      local aim is (tgtPos() - (burnPos + burnVel * lookahead)) + tgt:VELOCITY:SURFACE * getTimeToLand(vThrottle).

      vecGui("aim", aim, white).
      vecGui("burnPos", burnPos, blue).
      vecGui("tgt", tgtPos(), white).
      vecGui("burnVel", burnVel, yellow).
      vecGui("vel", SHIP:VELOCITY:SURFACE, red).
      logGui("q", SHIP:Q).
      local dist is VXCL(SHIP:UP:VECTOR, aim).
      local tvel is SQRT(2*hacc*MAX(0,dist:MAG-4)).
      local tvelLin is dist:MAG / 1.5.

      local tvelVec is V(0,0,0).
      if dist:MAG > 10 {
        set tvelVec to dist:NORMALIZED * tvel.
      } else {
        set tvelVec to dist:NORMALIZED * MAX(tvel, tvelLin).
      }

      local tdiff is tvelVec - VXCL(SHIP:UP:VECTOR, burnVel).
      local hStopTime is (tdiff:MAG + tvelVec:MAG) / hacc.
      if hStopTime > getBurnDuration() * 0.9 {
        gui["warn"]("Error unable to stop horizontal speed in time.").
      }

      return tvelVec.
    }, vThrottle, lookahead, Klimit, hKp, AoA).

    if bodylift {
      on THROTTLE {
        control["hSpeedInvert"](THROTTLE = 0 or SHIP:Q > 0.15).
        if not done {PRESERVE.}
      }
      control["hSpeedInvert"](THROTTLE = 0 or SHIP:Q > 0.15).
    }

    local t is TIME:SECONDS.
    local i is 0.
    until done {
      local tnew is TIME:SECONDS.
      print tnew - t at(0,12).
      set t to tnew.
      print i at(0,13).
      set i to i+1.
      wait 0.
    }.

    guiCtx["remove"]().
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
    parameter remaining is (SHIP:AVAILABLETHRUST / SHIP:MASS)/2.

    local guiCtx is gui["createContext"]("Break Orbit").
    local logGui is guiCtx["log"].

    logGui("Remaining Speed", remaining).
    logGui("Speed", SHIP:VELOCITY:SURFACE:MAG).

    print "Breaking orbit.".
    lock STEERING to SURFACERETROGRADE.
    wait 10.
    lock THROTTLE to 1.
    print "Killing speed.".
    until VELOCITY:SURFACE:MAG < remaining {
      logGui("Speed", SHIP:VELOCITY:SURFACE:MAG).
      wait 0.
    }
    lock THROTTLE to 0.
    guiCtx["remove"]().
    wait 0.
  }

  //*
  //* primitive function to land using parachutes
  //* does not suit any situation
  //*
  function parachute {
    parameter stagenr is 0.
    parameter pro is false.
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
    if pro {
      lock STEERING to SURFACEPROGRADE.
    } else {
      lock STEERING to SURFACERETROGRADE.
    }
    wait 0.

    when SHIP:ALTITUDE > SHIP:BODY:ATM:HEIGHT then {
      PANELS on.

      when SHIP:ALTITUDE < SHIP:BODY:ATM:HEIGHT then {
        PANELS off.
      }
    }

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
    parameter y.

    local g is BODY:MU/(BODY:RADIUS + (y/2))^2.
    return g - ((SHIP:ORBIT:VELOCITY:ORBIT:SQRMAGNITUDE - SHIP:VERTICALSPEED^2)/(BODY:RADIUS)).
  }
  function getTimeToImpact {
    parameter y is ALT:RADAR.
    // x = v*t + 1/2 * a * t^2
    // t = (-v + sqrt(v^2 + 2 * a * h))/a
    local a is getA(y).
    if y < 0 { return 0. }.

    return (SHIP:VERTICALSPEED + SQRT(SHIP:VERTICALSPEED^2 + 2 * a * y)) / a.
  }
  function getSpeed {
    parameter y is ALT:RADAR.
    parameter t is getTimeToImpact(y).

    local a is getA(y).

    // v = v0 + a * t
    return -SHIP:VERTICALSPEED + a * t.
  }
  function findBurnThottle {
    parameter duration.
    parameter y is ALT:RADAR.

    return getSpeed(y) * SHIP:MASS / (duration * SHIP:AVAILABLETHRUST).
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

    local avgVel is (getBurnVelocity(throt, y) + SHIP:VELOCITY:SURFACE) / 2.

    return avgVel * getTimeToBurn(throt, y).
  }
  function getBurnVelocity {
    parameter throt is 1.
    parameter y is ALT:RADAR.

    local hvel is VXCL(SHIP:UP:VECTOR, SHIP:VELOCITY:SURFACE).
    local vvel is VXCL(hvel, SHIP:VELOCITY:SURFACE).
    local ttb is getTimeToBurn(throt, y).

    local hspeedup is (vvel:MAG + getSpeed())/2 * hvel:MAG / (BODY:RADIUS + y + (ALTITUDE - y) / 2) * ttb.
    set hvel:MAG to hvel:MAG + hspeedup.

    return (vvel + hvel) + getA(y) * (-SHIP:UP:VECTOR) * ttb.
  }

  export(lex(
    "land", land@,
    "jebLand", jebLand@,
    "breakOrbit", breakOrbit@,
    "parachute", parachute@
  )).
}
