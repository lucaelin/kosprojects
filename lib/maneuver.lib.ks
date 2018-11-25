@lazyglobal off.
{
  local orbit is import("lib/orbit").
  local math is import("lib/math").
  local util is import("lib/util").
  local gui is import("lib/gui").

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
    local escBodyPrograde is orbit["getProVector"](escBodyTrue, bodyEccVec, bodyNrml, BODY:ORBIT:SEMIMAJORAXIS).
    if escBodyPrograde:MAG = 0 {
      // body is perfectly circular
      print "Body is perfectly circular...".
      set escBodyPrograde to ANGLEAXIS(escBodyTrue - SHIP:BODY:ORBIT:TRUEANOMALY, -bodyNrml) * SHIP:BODY:ORBIT:VELOCITY:ORBIT.
    }

    local escAngle is orbit["vecToTrue"](escProVec, escBodyPrograde).

    local dV is endVel-startVel.

    local trueAnomaly is angle - escAngle.
    exec(trueAnomaly+360, dV, 0, 0).
    print "Escape burn complete.".

    local oldbody is SHIP:BODY.
    wait 1.
    local warptime is TIME:SECONDS + escTime + 10.
    KUNIVERSE:TIMEWARP:WARPTO(warptime).
    wait until TIME:SECONDS > warptime.
    wait until KUNIVERSE:TIMEWARP:ISSETTLED.
    wait until not (SHIP:BODY = oldbody).
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

    exec(trueAnomaly, dv, 0, 0).
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
  //* parameter src the orbitable to transfer from
  //* parameter dryRun only warp close to interplanetary alignment but dont transfer
  //*
  function simpleTransfer {
    parameter dst is TARGET.
    parameter src is SHIP.
    parameter dryRun is false.

    local guiCtx is gui["createContext"]("Hohmann Transfer").
    local logGui is guiCtx["log"].
    local trackGui is guiCtx["track"].
    local vecGui is guiCtx["vec"].

    local dstW is ( 2 * CONSTANT:PI * dst:ORBIT:SEMIMAJORAXIS * dst:ORBIT:SEMIMINORAXIS ) / (dst:ORBIT:PERIOD * (dst:ALTITUDE + dst:BODY:RADIUS)^2) * RADTODEG.
    local dstAvgW is 360 / dst:ORBIT:PERIOD.
    local dstEstW is dstAvgW.
    local s is src:ORBIT:SEMIMAJORAXIS.
    local d is dst:ORBIT:SEMIMAJORAXIS.// + 1400000000.
    local h is (s+d)/2.
    local p is 1 / (2 * SQRT(d^3 / h^3)) - 0.5.

    local srcVel is src:ORBIT:VELOCITY:ORBIT.
    wait 0.
    local srcBodyPos is src:BODY:POSITION - src:POSITION.
    local srcPe is orbit["getPeriapsisVector"](
      srcVel,    // velocity vector
      -srcBodyPos,    // position vector
      src:BODY:MU,
      src:BODY:RADIUS + src:ORBIT:PERIAPSIS
    ).
    local srcNormVec is VCRS(srcVel, -srcBodyPos).

    print "transferangle " + p*360.
    local dstmean is orbit["vecToMean"](dst:POSITION - src:POSITION - srcBodyPos, src:ORBIT:ECCENTRICITY, srcPe, srcNormVec) + p * 360.
    print "dstmean " + dstmean.
    local mymean is orbit["vecToMean"](-srcBodyPos, src:ORBIT:ECCENTRICITY, srcPe, srcNormVec).
    print "mymean " + mymean.
    local meandiff is math["diffAnomaly"](mymean, dstmean).
    print "diff " + meandiff.
    print dstW.
    print "- phasing -".
    local catchup is math["orbitalPhasingW"](360 / src:ORBIT:PERIOD, dstEstW).
    print math["orbitalPhasingW"](360 / src:ORBIT:PERIOD, dstEstW).
    print math["orbitalPhasing"](src:ORBIT:PERIOD, dst:ORBIT:PERIOD).
    print "catchup " + catchup.
    local orbits is 0.
    if catchup > 0  {
      set orbits to meandiff / catchup.
    } else {
      set orbits to (360-meandiff) / -catchup.
    }
    print "orbits " + orbits + "("+(orbits*src:ORBIT:PERIOD/60/60)+"h)".
    print "orbitsdeg " + orbits * 360.
    local startmean is mymean + orbits * 360.
    print "startmean " + startmean.
    local trueAnomaly is math["meanToTrue"](startmean, src:ORBIT:ECCENTRICITY).
    print "trueAnomaly " + trueAnomaly.

    wait 0.

    local pos is orbit["trueToVec"](trueAnomaly, srcPe, srcNormVec, src:ORBIT:SEMIMAJORAXIS, src:ORBIT:ECCENTRICITY).

    // CLEARVECDRAWS().
    // VECDRAW(src:POSITION, srcBodyPos, yellow, "srcBodyPos", 1, true).
    // VECDRAW(src:BODY:POSITION, pos, white, "pos", 1, true).
    // VECDRAW(src:POSITION, srcBodyPos, yellow, "srcBodyPos", 1, true).
    // VECDRAW(src:BODY:POSITION, srcPe, green, "srcPe", 1, true).
    // VECDRAW(src:BODY:POSITION, srcNormVec:NORMALIZED * srcPe:MAG, red, "srcNormVec", 1, true).
    // awaitInput().
    // CLEARVECDRAWS().

    wait 0.
    local dstDir is -pos.
    local dstPe is orbit["getPeriapsisVector"](
      dst:ORBIT:VELOCITY:ORBIT,
      dst:ORBIT:POSITION - src:POSITION - srcBodyPos,
      src:BODY:MU,
      src:BODY:RADIUS + dst:ORBIT:PERIAPSIS
    ).
    local dstTrue is orbit["vecToTrue"](dstDir, dstPe, -vcrs(dst:ORBIT:VELOCITY:ORBIT, dst:ORBIT:POSITION - src:POSITION - srcBodyPos)).
    local dstAlt is math["radiusAtTrue"](dstTrue, dst:ORBIT:SEMIMAJORAXIS, dst:ORBIT:ECCENTRICITY).

    local pro is VCRS(pos, srcNormVec).
    set pro:MAG to math["velAtRadius"](pos:MAG, src:ORBIT:SEMIMAJORAXIS, src:BODY:MU).
    local cosy is VCRS(pos, pro):MAG / (pos:MAG * pro:MAG).
    local dV is SQRT((2 * src:BODY:MU * dstAlt * (dstAlt - pos:MAG)) / (pos:MAG * dstAlt ^ 2 - pos:MAG ^ 3 * cosy ^ 2)) - pro:MAG.

    print "deltaV: " + dV.

    if src = SHIP {
      exec(trueAnomaly, dV, 0, 0).
    } else if src = SHIP:BODY {
      local dt is orbits * src:ORBIT:PERIOD.
      local t is TIME:SECONDS + dt.
      local ts is TIME:SECONDS + dt * 0.9 - 2*6*60*60.
      KUNIVERSE:TIMEWARP:WARPTO(ts).
      wait until TIME:SECONDS > ts.
      wait until KUNIVERSE:TIMEWARP:ISSETTLED.
      wait 5.

      if dryRun {
        guiCtx["remove"]().
        return LEX("trueAnomaly", trueAnomaly, "prograde", dV, "normal", 0, "radial", 0).
      }

      if dt > 10 * 10000 {
        print "redoing calculation.".
        return simpleTransfer(dst, src).
      }

      KUNIVERSE:TIMEWARP:WARPTO(t).
      wait until TIME:SECONDS > t.
      wait until KUNIVERSE:TIMEWARP:ISSETTLED.


      wait 1.
      if dV > 0 {
        escape(dV, 0).
      } else {
        escape(ABS(dV), 180).
      }
      guiCtx["remove"]().
    } else {
      guiCtx["remove"]().
      return LEX("trueAnomaly", trueAnomaly, "prograde", dV, "normal", 0, "radial", 0).
    }
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

    wait 1.
    KUNIVERSE:TIMEWARP:WARPTO(burntime - 20 - 1).
    wait until TIME:SECONDS > burntime - 20 - 1.
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

    local tgtpe is 0. // TODO: TARGET PE VECTOR //-vcrs(tgt:ORBIT:VELOCITY:ORBIT,BODY:POSITION-tgt:POSITION).
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
  //* turn the current orbit into a polar one at the next apoapsis
  //*
  function polarize {
    local pro is VANG(NORMAL:VECTOR:NORMALIZED, -BODY:ANGULARVEL) < 90.
    local peri is orbit["getPeriapsisVector"]().
    local ns is -BODY:ANGULARVEL.
    if not pro {
      set ns to BODY:ANGULARVEL.
    }
    local tgt is VCRS(peri, ns).

    adjustInclination(tgt, false).
  }

  //*
  //* match inclination with a given target at the closest ascending or descending node
  //* parameter tgt the target to match inclination with
  //*
  function tgtInclination {
    parameter tgt is TARGET.

    local ascending is true.

    local tgtnrml is -vcrs(tgt:ORBIT:VELOCITY:ORBIT,BODY:POSITION-tgt:POSITION).
    local trueAnomaly is orbit["ascendingTrueAnomaly"](tgtnrml).
    if math["diffAnomaly"](SHIP:ORBIT:TRUEANOMALY, trueAnomaly) > 180 {
      set ascending to false.
    }

    adjustInclination(tgtnrml, ascending).
  }
  //*
  //* match inclination with a given normal vector
  //* parameter tgtnrml the normal vector to match
  //* parameter ascending if the node should be placed at the ascending node
  //*
  function adjustInclination {
    parameter tgtnrml is -BODY:ANGULARVEL.
    parameter ascending is true.

    local trueAnomaly is orbit["ascendingTrueAnomaly"](tgtnrml).
    if not ascending {
      set trueAnomaly to orbit["ascendingTrueAnomaly"](-tgtnrml).
    }

    local inclination is VANG(tgtnrml:NORMALIZED, NORMAL:VECTOR:NORMALIZED).
    if not ascending {
      set inclination to -inclination.
    }
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

    if dV = 0 {
      unlock THROTTLE.
      unlock STEERING.
      wait 0.
      return.
    }

    local maneuvernode is "".
    if CAREER():CANMAKENODES {
      set maneuvernode to NODE(nodetime, outDV, normDV, proDV).
      ADD maneuvernode.
    }

    local mnvPos is orbit["trueToVec"](trueAnomaly).
    local mnvPosStored is math["storeVector"](mnvPos).
    local mnvVel is burnVector(trueAnomaly, proDV + math["velAtTrue"](trueAnomaly), normDV, outDV).
    local mnvVelStored is math["storeVector"](mnvVel).
    local mnvEcc is -orbit["getEccentricityVector"](mnvVel, mnvPos, BODY:MU). // TODO find out why negative?!
    local mnvEccStored is math["storeVector"](mnvEcc).
    local mnvNrml is -VCRS(mnvPos, mnvVel):NORMALIZED.
    local mnvNrmlStored is math["storeVector"](mnvNrml).
    local mnvSMA is 1 / (2 / mnvPos:MAG - mnvVel:MAG^2 / BODY:MU).

    //local lock curMnvTrue to orbit["vecToTrue"](-BODY:POSITION, math["loadVector"](mnvEccStored), math["loadVector"](mnvNrmlStored)).
    local lock curMnvTrue to orbit["vecToTrue"](math["loadVector"](mnvPosStored)).
    //local lock curMnvVel to orbit["getVelVector"](
    //  curMnvTrue,
    //  math["loadVector"](mnvEccStored),
    //  math["loadVector"](mnvNrmlStored),
    //  mnvSMA,
    //  BODY:MU
    //).
    local lock curMnvVel to orbit["getVelVector"](curMnvTrue).
    //local lock diff to curMnvVel - SHIP:ORBIT:VELOCITY:ORBIT.
    local lock diff to math["loadVector"](mnvVelStored) - curMnvVel.
    lock STEERING to LOOKDIRUP(diff, SHIP:FACING:TOPVECTOR).

    local done is false.
    local guiCtx is gui["createContext"]("maneuver").
    local logGui is guiCtx["log"].
    local trackGui is guiCtx["track"].
    local vecGui is guiCtx["vec"].


    logGui("dV total", maneuvernode:BURNVECTOR:MAG, "m/s").
    logGui("dV remaining", maneuvernode:BURNVECTOR:MAG, "m/s").
    trackGui("throttle", { return THROTTLE. }).
    trackGui("time to node", { return nodetime - TIME:SECONDS. }, "s").
    trackGui("time to burn", { return burntime - TIME:SECONDS. }, "s").
    on TIME:SECONDS {
      return.
      CLEARVECDRAWS().
      CLEARSCREEN.
      print "curMnvTrue:" + curMnvTrue.
      print "    mnvSMA:" + mnvSMA.
      print "     hdiff:" + (math["radiusAtTrue"](curMnvTrue) - math["loadVector"](mnvPosStored):MAG).
      print "     vdiff:" + diff:MAG.

      VECDRAW(BODY:POSITION, math["loadVector"](mnvPosStored), rgb(255,200,0), "mnvPos", 1, true).
      VECDRAW(V(0,0,0), diff, white, "diff", 1, true).
      VECDRAW(V(0,0,0), curMnvVel, blue, "curMnvVel", 1, true).
      VECDRAW(V(0,0,0), SHIP:ORBIT:VELOCITY:ORBIT, red, "vel", 1, true).
      VECDRAW(V(0,0,0), math["loadVector"](mnvVelStored), purple, "mnvVel", 1, true).
      VECDRAW(V(0,10,0), math["loadVector"](mnvEccStored):NORMALIZED, white, "Ecc", 1, true).
      VECDRAW(V(0,10,0), math["loadVector"](mnvNrmlStored):NORMALIZED, yellow, "Nrml", 1, true).
      if not done PRESERVE.
    }

    local safetymargin is (burntime - TIME:SECONDS) * 0.9.
    until safetymargin < 60*60*6*10 {
      wait 1.
      local warpto is TIME:SECONDS + safetymargin.
      KUNIVERSE:TIMEWARP:WARPTO(warpto).
      wait 0.
      wait until KUNIVERSE:TIMEWARP:ISSETTLED.
      wait 0.
      wait until TIME:SECONDS > warpto.
      wait 0.
      set safetymargin to (burntime - TIME:SECONDS) * 0.9.
    }
    wait 1.
    KUNIVERSE:TIMEWARP:WARPTO(burntime - warpmargin - 1).
    wait 0.
    wait until KUNIVERSE:TIMEWARP:ISSETTLED.
    wait 0.
    wait until TIME:SECONDS > burntime.

    local lock acc to (SHIP:AVAILABLETHRUST+SHIP:MASS*0.00001) / SHIP:MASS.
    if CAREER():CANMAKENODES {
      lock STEERING to LOOKDIRUP(maneuvernode:BURNVECTOR, SHIP:FACING:TOPVECTOR).
      lock THROTTLE to CLAMP(0.01, 1, maneuvernode:BURNVECTOR:MAG / (acc * 2)).
      trackGui("dV remaining", { return maneuvernode:BURNVECTOR:MAG. }, "m/s").
      trackGui("precision", { return SHIP:MAXTHRUST / SHIP:MASS * 0.001. }, "m/s").
      trackGui("angle offset", { return VANG(maneuvernode:BURNVECTOR, util["getThrustVector"]()). }, "°").
      wait until maneuvernode:BURNVECTOR:MAG < SHIP:MAXTHRUST / SHIP:MASS * 0.001 or VANG(maneuvernode:BURNVECTOR, util["getThrustVector"]()) > 45.
    } else {
      lock STEERING to LOOKDIRUP(diff, SHIP:FACING:TOPVECTOR).
      lock THROTTLE to CLAMP(0.01, 1, diff:MAG / (acc * 2)).
      trackGui("dV remaining", { return diff:MAG. }, "m/s").
      trackGui("precision", { return SHIP:MAXTHRUST / SHIP:MASS * 0.001. }, "m/s").
      trackGui("angle offset", { return VANG(diff, util["getThrustVector"]()). }, "°").
      wait until diff:MAG < SHIP:MAXTHRUST / SHIP:MASS * 0.001 or VANG(diff, util["getThrustVector"]()) > 45.
    }
    lock THROTTLE to 0.

    unlock THROTTLE.
    unlock STEERING.
    //awaitInput().

    set done to true.
    guiCtx["remove"]().

    wait 1.
    if CAREER():CANMAKENODES {
      REMOVE maneuvernode.
    }
    wait 0.
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
    "polarize", polarize@,
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
