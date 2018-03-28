@lazyglobal off.
{
  local orbit is import("lib/orbit").
  local math is import("lib/math").

  function raiseAp {
    parameter dst.

    local r is PERIAPSIS + BODY:RADIUS.

    local ad is (BODY:RADIUS + dst + r) / 2.

    local v1 is SQRT(BODY:MU*((2 / r) - (1 / SHIP:ORBIT:SEMIMAJORAXIS))).
    local v2 is SQRT(BODY:MU*((2 / r) - (1 / ad))).
    local dV is v2 - v1.

    exec(0, dV, 0, 0).
  }
  function raisePe {
    parameter dst.

    local r is APOAPSIS + BODY:RADIUS.

    local ad is (BODY:RADIUS + dst + r) / 2.

    local v1 is SQRT(BODY:MU*((2 / r) - (1 / SHIP:ORBIT:SEMIMAJORAXIS))).
    local v2 is SQRT(BODY:MU*((2 / r) - (1 / ad))).
    local dV is v2 - v1.

    exec(180, dV, 0, 0).
  }

  function simpleTransfer {
    parameter dst is TARGET.

    local s is SHIP:ORBIT:SEMIMAJORAXIS.
    local d is dst:ORBIT:SEMIMAJORAXIS.
    local h is (s+d)/2.
    local p is 1 / (2 * SQRT(d^3 / h^3)) - 0.5.
    //print "transferangle " + p*360.
    local dstmean is orbit["vecToMean"](dst:ORBIT:POSITION-BODY:POSITION) + p * 360.
    //print "dstmean " + dstmean.
    local mymean is SHIP:ORBIT:MEANANOMALYATEPOCH.
    //print "mymean " + mymean.
    local meandiff is math["diffAnomaly"](mymean, dstmean).
    //print "diff " + meandiff.
    local catchup is math["orbitalPhasing"](SHIP:ORBIT:PERIOD, dst:ORBIT:PERIOD).
    //print "catchup " + catchup.
    local orbits is 0.
    if catchup > 0  {
      set orbits to meandiff / catchup.
    } else {
      set orbits to (360-meandiff) / -catchup.
    }
    //print "orbits " + orbits.
    //print "orbitsdeg " + orbits * 360.
    local startmean is mymean + orbits * 360.
    //print "startmean " + startmean.
    local trueAnomaly is math["meanToTrue"](startmean).
    //print trueAnomaly.

    wait 5.

    local pos is orbit["trueToVec"](trueAnomaly).
    local dstDir is -pos.
    local dstPe is orbit["getPeriapsisVector"](
      dst:VELOCITY:ORBIT,
      dst:ORBIT:POSITION - BODY:POSITION,
      BODY:MU,
      BODY:RADIUS + dst:PERIAPSIS
    ).
    local dstTrue is orbit["vecToTrue"](dstDir, dstPe, -vcrs(dst:VELOCITY:ORBIT, dst:ORBIT:POSITION - BODY:POSITION)).
    local dstAlt is math["radiusAtTrue"](dstTrue, dst:ORBIT:SEMIMAJORAXIS, dst:ORBIT:ECCENTRICITY).

    local norm is NORMAL:VECTOR:NORMALIZED.
    local pro is VCRS(pos, norm).
    set pro:MAG to math["velAtRadius"](pos:MAG).
    local cosy is VCRS(pos, pro):MAG / (pos:MAG * pro:MAG).
    local dV is SQRT((2 * BODY:MU * dstAlt * (dstAlt - pos:MAG)) / (pos:MAG * dstAlt ^ 2 - pos:MAG ^ 3 * cosy ^ 2)) - pro:MAG.

    print "deltaV: " + dV.

    exec(trueAnomaly, dV, 0, 0).
  }

  function circularize {
    parameter atPariapsis is false.

    local r is 0.
    if not atPariapsis {
      set r to APOAPSIS + BODY:RADIUS.
    } else {
      set r to PERIAPSIS + BODY:RADIUS.
    }

    local v1 is SQRT(BODY:MU*((2/r)-(1/SHIP:ORBIT:SEMIMAJORAXIS))).
    local v2 is SQRT(BODY:MU*((2/r)-(1/r))).
    local dV is v2 - v1.

    print "Circularization dV: "+ dV.

    if not atPariapsis {
      exec(180, dV, 0, 0).
    } else {
      exec(0, dV, 0, 0).
    }
  }.

  function capture {
    parameter p is SHIP:ORBIT:PERIAPSIS.
    parameter a is SHIP:ORBIT:SEMIMAJORAXIS.
    parameter r is SHIP:BODY:RADIUS.
    parameter mu is SHIP:BODY:MU.

    // Calculate Escape Velocity for when we burn at Periapsis
    local Vesc is SQRT((2*mu)/(r+p)).
    // Using Escape velocity at Periapsis Calculate Orbital velocity.
    local Vorb is Vesc/SQRT(2).

    // Calculate Vinf hyperbolic excess velocity.
    local Vinf is SQRT(ABS(mu/a)).

    local Vcap is SQRT(Vesc^2 + Vinf^2) - Vorb.

    print "Capture dV: "+ Vcap.

    local burntime is TIME:SECONDS + ETA:PERIAPSIS - burnDuration(Vcap) / 2.

    local maneuvernode is NODE(burntime + burnDuration(Vcap) / 2, 0, 0, -Vcap).
    ADD maneuvernode.

    lock STEERING to RETROGRADE.

    wait 0.
    KUNIVERSE:TIMEWARP:WARPTO(burntime - 20 - 1).
    wait until KUNIVERSE:TIMEWARP:ISSETTLED.
    wait 1.
    wait until TIME:SECONDS > burntime.
    lock THROTTLE to 1.
    wait until SHIP:ORBIT:APOAPSIS > 0.
    wait until SHIP:ORBIT:APOAPSIS < BODY:SOIRADIUS * 0.9.
    lock THROTTLE to 0.

    wait until true.
    unlock THROTTLE.
    unlock STEERING.
    wait 2.
    REMOVE maneuvernode.
  }.

  function tgtArgument {
    parameter tgt is TARGET.

    local tgtpe is 0. // TODO: TARGET PE VECTOR //-vcrs(tgt:VELOCITY:ORBIT,BODY:POSITION-tgt:POSITION).
    adjustInclination(tgtpe).
  }

  function adjustArgument {
    parameter tgtpe is ANGLEAXIS(45,-BODY:ANGULARVEL:NORMALIZED) * orbit["getPeriapsisVector"]().

    local trueAnomaly is orbit["vecToTrue"](tgtpe).

    if trueAnomaly > 180 {
      set trueAnomaly to trueAnomaly + ((360-trueAnomaly) / 2).
    } else {
      set trueAnomaly to trueAnomaly / 2.
    }

    local out is orbit["trueToVec"](math["trueToEcc"](trueAnomaly)):NORMALIZED. // using eccentric anomaly as input for trueToVec to get the correct out (because of flattening). the magnitude will be off, but normalized anyway.
    local norm is NORMAL:VECTOR:NORMALIZED.
    local pro is VCRS(out, norm):NORMALIZED.
    local trueVec is orbit["trueToVec"](trueAnomaly):NORMALIZED. // vector from COM to the node
    local tween is VCRS(trueVec, norm):NORMALIZED. // vector inbetween the current and the target prograde

    local inclination is 2*VANG(tween, pro). // not an inclination really but the formula is the same
    local start is math["velAtTrue"](trueAnomaly).
    local DV is 2 * start * SIN(inclination / 2).

    local rDV is COS(inclination/2) * DV.
    local pDV is SIN(inclination/2) * DV.

    if trueAnomaly > 180 {
      exec(trueAnomaly, -pDV, 0, rDV).
    } else {
      exec(trueAnomaly, -pDV, 0, -rDV).
    }
  }

  function tgtInclination {
    parameter tgt is TARGET.

    local tgtnrml is -vcrs(tgt:VELOCITY:ORBIT,BODY:POSITION-tgt:POSITION).
    adjustInclination(tgtnrml).
  }
  function adjustInclination {
    parameter tgtnrml is -BODY:ANGULARVEL.

    local trueAnomaly is orbit["ascendingTrueAnomaly"](tgtnrml).
    local inclination is VANG(tgtnrml:NORMALIZED, NORMAL:VECTOR:NORMALIZED).
    local start is math["velAtTrue"](trueAnomaly).
    local DV is 2 * start * SIN(inclination / 2).

    local nDV is COS(inclination/2) * DV.
    local pDV is SIN(inclination/2) * DV.

    exec(trueAnomaly, -pDV, -nDV, 0).
  }

  function show {
    parameter trueAnomaly.
    parameter proDV.
    parameter normDV.
    parameter inDV.

    local out is orbit["trueToVec"](math["trueToEcc"](trueAnomaly)):NORMALIZED.
    local norm is NORMAL:VECTOR:NORMALIZED.
    local pro is VCRS(out, norm):NORMALIZED.
    //CLEARVECDRAWS().
    vecdraw(body:position + orbit["trueToVec"](trueAnomaly), pro, RGB(1,0,0), "pro", 10000, true, 1/100000).
    vecdraw(body:position + orbit["trueToVec"](trueAnomaly), norm, RGB(1,0,1), "norm", 10000, true, 1/100000).
    vecdraw(body:position + orbit["trueToVec"](trueAnomaly), out, RGB(0,1,1), "out", 10000, true, 1/100000).
    vecdraw(body:position + orbit["trueToVec"](trueAnomaly), out*(inDV) + norm*normDV + pro*proDV, RGB(0,1,1), "mnvr", 1, true).

    //global p is vecdraw(v(0,0,0), PROGRADE:VECTOR, RGBA(1,0,0,0.5), "rpro", 1, true).
    //set p:VECUPDATER to { return PROGRADE:VECTOR. }.
    //global n is vecdraw(v(0,0,0), NORMAL:VECTOR, RGBA(1,0,1,0.5), "rnorm", 1, true).
    //set n:VECUPDATER to { return NORMAL:VECTOR. }.
    //global r is vecdraw(v(0,0,0), RADIALOUT:VECTOR, RGBA(0,1,1,0.5), "rout", 1, true).
    //set r:VECUPDATER to { return RADIALOUT:VECTOR. }.
  }

  function exec {
    parameter trueAnomaly.
    parameter proDV.
    parameter normDV.
    parameter inDV.
    parameter warpmargin is 20.

    //show(trueAnomaly, proDV, normDV, inDV).

    local dV is sqrt(proDV^2 + normDV^2 + inDV^2).
    local duration is burnDuration(dV).
    local burntime is TIME:SECONDS + orbit["timeToTrue"](trueAnomaly) - duration / 2.

    // steering calculations
    local out is orbit["trueToVec"](math["trueToEcc"](trueAnomaly)):NORMALIZED. // using eccentric anomaly as input for trueToVec to get the correct out (because of flattening). the magnitude will be off, but normalized anyway.
    local norm is NORMAL:VECTOR:NORMALIZED.
    local pro is VCRS(out, norm):NORMALIZED.

    local burnVec is out*inDV + norm*normDV + pro*proDV.
    local burnVecStored is math["storeVector"](burnVec).  // store the vector in relation to the SOLARPRIMEVECTOR because everything else might drift over time

    lock STEERING to LOOKDIRUP(math["loadVector"](burnVecStored), SHIP:FACING:TOPVECTOR).

    local maneuvernode is NODE(burntime + duration / 2, inDV, normDV, proDV).
    ADD maneuvernode.

    wait 0.
    KUNIVERSE:TIMEWARP:WARPTO(burntime - warpmargin - 1).
    wait until KUNIVERSE:TIMEWARP:ISSETTLED.
    wait until TIME:SECONDS > burntime.
    if dV = 0 { return. }

    // redoing steering calculations
    set out to orbit["trueToVec"](math["trueToEcc"](trueAnomaly)):NORMALIZED. // using eccentric anomaly as input for trueToVec to get the correct out (because of flattening). the magnitude will be off, but normalized anyway.
    set norm to NORMAL:VECTOR:NORMALIZED.
    set pro to VCRS(out, norm):NORMALIZED.

    set burnVec to out*inDV + norm*normDV + pro*proDV.
    set burnVecStored to math["storeVector"](burnVec).  // store the vector in relation to the SOLARPRIMEVECTOR because everything else might drift over time

    lock STEERING to LOOKDIRUP(math["loadVector"](burnVecStored), SHIP:FACING:TOPVECTOR).

    local dVadded is 0.
    local lastTime is TIME:SECONDS.
    local accel is 0.
    local dT is 0.
    local steeringoffset is 0.
    local thrustGuard is SHIP:AVAILABLETHRUST * 0.00001. // prevent NaN
    lock THROTTLE to clamp(0, 1, (dV - dVadded) / ((2*SHIP:AVAILABLETHRUST + thrustGuard)/SHIP:MASS)).
    until dVadded > dV * 0.999 {
      wait 0.
      set dT to TIME:SECONDS - lastTime.
      set lastTime to TIME:SECONDS.
      set accel to (SHIP:AVAILABLETHRUST * THROTTLE / SHIP:MASS).
      set steeringoffset to VDOT(SHIP:FACING:VECTOR:NORMALIZED, STEERING:VECTOR).
      set dVadded to dVadded + (accel * dT * steeringoffset).
    }
    unlock THROTTLE.
    unlock STEERING.
    wait 1.
    REMOVE maneuvernode.
  }.

  function execNode {
    print "execNode is not currently supported.".
  }.

  function burnDuration {
    parameter dV.

    local enginelist is LIST().
    list ENGINES in enginelist.
    local count is 0.
    local ispsum is 0.

    for e in enginelist {
      if e:IGNITION {
        set count to count + 1.
        set ispsum to ispsum + e:ISP.
      }
    }

    local f is SHIP:AVAILABLETHRUST.   // Engine Thrust (kg * m/s²)
    local m is SHIP:MASS.        // Starting mass (kg)
    local e is CONSTANT():E.            // Base of natural log
    local isp is ispsum / count.             // Engine ISP (s)
    local g is 9.82.                 // Gravitational acceleration constant (m/s²)

    return (m - (m / e^(dv / (isp * g)))) / (f / (isp * g)).
  }.

  export(lex(
    "adjustArgument", adjustArgument@,
    "tgtArgument", tgtArgument@,
    "adjustInclination", adjustInclination@,
    "tgtInclination", tgtInclination@,
    "circularize", circularize@,
    "capture", capture@,
    "simpleTransfer", simpleTransfer@,
    "raiseAp", raiseAp@,
    "raisePe", raisePe@,
    "exec", exec@,
    "show", show@,
    "execNode", execNode@
  )).
}