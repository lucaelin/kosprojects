@lazyglobal off.
{
  local orbit is import("lib/orbit").
  local math is import("lib/math").
  local util is import("lib/util").

  //*
  //* escape the SOI of the body from a circular orbit with a given excess velocity and a given angle from the prograde direction of the bodies orbits on the ship current plane
  //* the bodies orbital prograde is projected onto the ships orbital plane, so you need to make sure that the plane is correct for your desired escape
  //* parameter excess is the velocity to remain at SOI leave
  //* parameter angle is the targeted angle at which to leave relative to the bodies prograde direction
  //*
  function escape {
    parameter excess is 0.
    parameter angle is 0.

    local soi is BODY:SOIRADIUS.
    //print "     soi: " + soi.
    local endSMA is 1 / (2 / soi - excess^2 / BODY:MU).
    //print "  endSMA: " + endSMA.

    local r is PERIAPSIS + BODY:RADIUS.
    //print "       r: " + r.
    local startVel is math["velAtRadius"](r).
    //print "startVel: " + startVel.
    local endVel is math["velAtRadius"](r, endSMA).
    //print "  endVel: " + endVel.
    local endE is (-r) / endSMA + 1.
    //print "    endE: " + endE.
    local escAno is math["trueAtRadius"](soi, endSMA, endE).
    //print "  escAno: " + escAno.
    local escEVec is orbit["getEccentricityVector"]():NORMALIZED * endE. // assume to keep the current periapsis position after burn
    local escProVec is VCRS(orbit["getOutVector"](escAno, escEVec), NORMAL:VECTOR):NORMALIZED.

    CLEARVECDRAWS().
    local escTime is orbit["timeToTrue"](escAno, 0, endE, endSMA).
    //print " escTime: " + escTime.
    local escBodyTrue is orbit["trueAtTime"](
      escTime,
      SHIP:BODY:ORBIT:PERIOD,
      SHIP:BODY:ORBIT:TRUEANOMALY,
      0,
      SHIP:BODY:ORBIT:ECCENTRICITY
    ).
    //print "   bodyTrue: " + SHIP:BODY:ORBIT:TRUEANOMALY.
    //print "escbodyTrue: " + escBodyTrue.
    local bodyPos is SHIP:BODY:POSITION - SHIP:BODY:BODY:POSITION.
    local bodyEccVec is orbit["getEccentricityVector"](SHIP:BODY:ORBIT:VELOCITY:ORBIT, bodyPos, SHIP:BODY:BODY:MU).
    local bodyNrml is VCRS(SHIP:BODY:ORBIT:VELOCITY:ORBIT, bodyPos).
    local escBodyPrograde is orbit["getProVector"](escBodyTrue, bodyEccVec, bodyNrml).

    local escAngle is orbit["vecToTrue"](escProVec, escBodyPrograde).
    //print "escAngle: " + escAngle.

    local dV is endVel-startVel.

    local trueAnomaly is angle - escAngle.
    exec(trueAnomaly+360, dV, 0, 0).

    local oldbody is SHIP:BODY.
    wait until not SHIP:BODY = oldbody.
    wait 1.
  }

  //*
  //* raise the orbits altitude at a given anomaly.
  //* parameter trueAnomaly the anomaly where the burn should take place
  //* parameter dst the altitude the orbit should have after the burn
  //* TODO: this is work in progress and currently not working and this function does not even make any sense right now
  //*
  function raiseAt {
    parameter trueAnomaly.
    parameter dst.

    local r is math["radiusAtTrue"](trueAnomaly).

    local ad is (BODY:RADIUS + dst + r) / 2.

    local v1 is SQRT(BODY:MU*((2 / r) - (1 / SHIP:ORBIT:SEMIMAJORAXIS))).
    local v2 is SQRT(BODY:MU*((2 / r) - (1 / ad))).
    local dV is v2 - v1.

    exec(trueAnomaly, dV, 0, 0).
  }

  //*
  //* change the periapsis altitude at a given anomaly.
  //* parameter trueAnomaly the anomaly where the burn should take place
  //* parameter p the altitude of the desired periapsis
  //*
  function changePe {
    parameter trueAnomaly.
    parameter p.

    local dv is orbit["changePeAtTrue"](p, trueAnomaly).

    exec(trueAnomaly, dv, 0, 0, SHIP:ORBIT:PERIOD).
  }

  //*
  //* raise or lower the orbit at the current apoapsis
  //* parameter dst is the desired (lowest or highest) altitude in orbit
  //*
  function raiseAp {
    parameter dst.

    local r is PERIAPSIS + BODY:RADIUS.

    local ad is (BODY:RADIUS + dst + r) / 2.

    local v1 is SQRT(BODY:MU*((2 / r) - (1 / SHIP:ORBIT:SEMIMAJORAXIS))).
    local v2 is SQRT(BODY:MU*((2 / r) - (1 / ad))).
    local dV is v2 - v1.

    exec(0, dV, 0, 0).
  }

  //*
  //* raise or lower the orbit at the current periapsis
  //* parameter dst is the desired (lowest or highest) altitude in orbit
  //*
  function raisePe {
    parameter dst.

    local r is APOAPSIS + BODY:RADIUS.

    local ad is (BODY:RADIUS + dst + r) / 2.

    local v1 is SQRT(BODY:MU*((2 / r) - (1 / SHIP:ORBIT:SEMIMAJORAXIS))).
    local v2 is SQRT(BODY:MU*((2 / r) - (1 / ad))).
    local dV is v2 - v1.

    exec(180, dV, 0, 0).
  }

  //*
  //* use a simple hohmann transfer to the given target. this only works if the ship and the target are in the same plane as well as in circular orbits
  //* parameter dst the target to transfer to
  //*
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
    print "orbits " + orbits.
    //print "orbitsdeg " + orbits * 360.
    local startmean is mymean + orbits * 360.
    //print "startmean " + startmean.
    local trueAnomaly is math["meanToTrue"](startmean).
    print trueAnomaly.

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

  //*
  //* circularize the current orbit
  //* parameter atPeriapsis where the maneuver should take place
  //*
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

  //*
  //* capture from a hyperbolic orbit to a circular one at the current periapsis
  //*
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

  //*
  //* TODO: implement if needed
  //*
  function tgtArgument {
    parameter tgt is TARGET.

    local tgtpe is 0. // TODO: TARGET PE VECTOR //-vcrs(tgt:VELOCITY:ORBIT,BODY:POSITION-tgt:POSITION).
    adjustInclination(tgtpe).
  }

  //*
  //* adjust the current orbits argument of periapsis
  //* parameter tgtpe is a vector where the new periapsis should be at relative to the body
  //*
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

  //*
  //* match inclination with a given target
  //* parameter tgt the target to match inclination with
  //*
  function tgtInclination {
    parameter tgt is TARGET.

    local tgtnrml is -vcrs(tgt:VELOCITY:ORBIT,BODY:POSITION-tgt:POSITION).
    adjustInclination(tgtnrml).
  }
  //*
  //* match inclination with a given normal vector
  //* parameter tgtnrml the normal vector to match
  //*
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
    parameter pro.
    parameter norm.
    parameter out.

    vecdraw(V(0, 0, 0), pro, RGB(1,0,0), "pro", 100, true, 0.5/100).
    vecdraw(V(0, 0, 0), norm, RGB(1,0,1), "norm", 100, true, 0.5/100).
    vecdraw(V(0, 0, 0), out, RGB(0,1,1), "out", 100, true, 0.5/100).
    vecdraw(V(0, 0, 0), out + norm + pro, RGB(0,1,1), "mnvr", 1, true).

    vecdraw(v(0,0,0), PROGRADE:VECTOR, RGBA(1,0,0,0.5), "rpro", 100, true, 0.5/100).
    //set p:VECUPDATER to { return PROGRADE:VECTOR. }.
    vecdraw(v(0,0,0), NORMAL:VECTOR, RGBA(1,0,1,0.5), "rnorm", 100, true, 0.5/100).
    //set n:VECUPDATER to { return NORMAL:VECTOR. }.
    vecdraw(v(0,0,0), RADIALOUT:VECTOR, RGBA(0,1,1,0.5), "rout", 100, true, 0.5/100).
    vecdraw(v(0,0,0), orbit["getOutVector"](SHIP:ORBIT:TRUEANOMALY), RGBA(0,0,1,0.5), "cout", 100, true, 0.5/100).
    //set r:VECUPDATER to { return RADIALOUT:VECTOR. }.
  }

  //*
  //* execute a maneuver at the given trueAnomaly
  //* parameter trueAnomaly where the maneuver should take place
  //* parameters proDV, normDV and outDV describing the maneuver
  //* parameter warpmargin when to timewarp to prior to the start of the maneuver burn
  //*
  function exec {
    parameter trueAnomaly.
    parameter proDV.
    parameter normDV.
    parameter outDV.
    parameter warpmargin is 20.

    //show(trueAnomaly, proDV, normDV, outDV).
    if trueAnomaly < SHIP:ORBIT:TRUEANOMALY set trueAnomaly to trueAnomaly + 360.

    local dV is sqrt(proDV^2 + normDV^2 + outDV^2).
    local duration is burnDuration(dV).
    local nodetime is TIME:SECONDS + orbit["timeToTrue"](trueAnomaly).
    local burntime is nodetime - duration / 2.
    set trueAnomaly to MODMOD(trueAnomaly, 360).

    // steering calculations
    lock STEERING to LOOKDIRUP(burnVector(trueAnomaly, proDV, normDV, outDV), SHIP:FACING:TOPVECTOR).

    local maneuvernode is NODE(nodetime, outDV, normDV, proDV).
    ADD maneuvernode.

    if dV = 0 {
      unlock THROTTLE.
      unlock STEERING.
      wait 1.
      REMOVE maneuvernode.
      return.
    }
    wait 0.
    KUNIVERSE:TIMEWARP:WARPTO(burntime - warpmargin - 1).
    wait until KUNIVERSE:TIMEWARP:ISSETTLED.
    if SHIP:ORBIT:ECCENTRICITY < 0.001 set trueAnomaly to orbit["trueAtTime"](nodetime).
    local burnVec is burnVector(trueAnomaly, proDV, normDV, outDV).
    lock STEERING to LOOKDIRUP(burnVec, SHIP:FACING:TOPVECTOR).
    wait until TIME:SECONDS > burntime-1.
    if SHIP:ORBIT:ECCENTRICITY < 0.001 set trueAnomaly to orbit["trueAtTime"](nodetime).
    local burnVec is burnVector(trueAnomaly, proDV, normDV, outDV).
    lock STEERING to LOOKDIRUP(burnVec, SHIP:FACING:TOPVECTOR).
    wait until TIME:SECONDS > burntime.

    if SHIP:ORBIT:ECCENTRICITY < 0.001 { set trueAnomaly to orbit["trueAtTime"](nodetime). }
    local burnVec is burnVector(trueAnomaly, proDV, normDV, outDV).
    local out is orbit["getOutVector"](trueAnomaly):NORMALIZED.
    local norm is NORMAL:VECTOR:NORMALIZED.
    local pro is VCRS(out, norm):NORMALIZED.
    lock STEERING to LOOKDIRUP(burnVec, SHIP:FACING:TOPVECTOR).

    local dVadded is 0.
    local lastTime is TIME:SECONDS.
    local steeringoffset is 0.
    local thrustGuard is SHIP:AVAILABLETHRUST * 0.00001. // prevent NaN
    lock THROTTLE to clamp(0, 1, (dV - dVadded) / ((2*SHIP:AVAILABLETHRUST + thrustGuard)/SHIP:MASS)).
    until dVadded > dV * 0.999 {
      wait 0.
      //CLEARVECDRAWS().
      //show(pro*proDV, norm*normDV, out*outDV).
      local dT is TIME:SECONDS - lastTime.
      set lastTime to TIME:SECONDS.
      local accel is util["getThrustVector"]() * THROTTLE / SHIP:MASS.
      set burnVec to burnVec - accel * dT.
      //VECDRAW(V(0,0,0), burnVec, blue, "burnVec", 1, true, 0.2).
      //VECDRAW(burnVec, -accel, blue, "accVec", 1, true, 0.2).
      set steeringoffset to VDOT(accel:NORMALIZED, STEERING:VECTOR:NORMALIZED).
      set dVadded to dVadded + (accel:MAG * dT * steeringoffset).
    }
    unlock THROTTLE.
    unlock STEERING.
    CLEARVECDRAWS().
    wait 1.
    REMOVE maneuvernode.
  }.

  function execNode {
    print "execNode is not currently supported.".
  }.

  function burnVector {
    parameter trueAnomaly.
    parameter proDV.
    parameter normDV.
    parameter outDV.

    local out is orbit["getOutVector"](trueAnomaly):NORMALIZED.
    local norm is NORMAL:VECTOR:NORMALIZED.
    local pro is VCRS(out, norm):NORMALIZED.

    return out*outDV + norm*normDV + pro*proDV.
  }

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
    "escape", escape@,
    "adjustArgument", adjustArgument@,
    "tgtArgument", tgtArgument@,
    "adjustInclination", adjustInclination@,
    "tgtInclination", tgtInclination@,
    "circularize", circularize@,
    "capture", capture@,
    "simpleTransfer", simpleTransfer@,
    "raiseAp", raiseAp@,
    "raisePe", raisePe@,
    "raiseAt", raiseAt@,
    "changePe", changePe@,
    "exec", exec@,
    "show", show@,
    "execNode", execNode@
  )).
}
