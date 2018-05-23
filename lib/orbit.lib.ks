@lazyglobal off.
{
  local math is import("lib/math").

  function horizonInvertedVector {
    parameter pointing.
    local east is VCRS(SHIP:UP:VECTOR, SHIP:NORTH:VECTOR).

    local trig_x is VDOT(SHIP:NORTH:VECTOR, pointing).
    local trig_y is VDOT(east, pointing).

    local result is ARCTAN2(trig_y, trig_x).

    if result < 0 {
      set result to 360 + result.
    }

    return HEADING(result, VANG(SHIP:UP:VECTOR, pointing)-90).
  }

  function getEccentricityVector {
    parameter v is SHIP:VELOCITY:ORBIT.    // velocity vector
    parameter r is -BODY:POSITION.    // position vector
    parameter mu is BODY:MU.

    local h to -VCRS(r, v).   // specific angular momentum vector

    return (-VCRS(v, h)) / mu - r / r:mag.
  }
  function getPeriapsisVector {
    parameter v is SHIP:VELOCITY:ORBIT.    // velocity vector
    parameter r is -BODY:POSITION.    // position vector
    parameter mu is BODY:MU.
    parameter l is BODY:RADIUS + PERIAPSIS.

    local vec is getEccentricityVector(v, r, mu).
    set vec:MAG to l.

    return vec.
  }
  function getOutVector {
    parameter trueAnomaly.
    parameter eccVec is getEccentricityVector().

    return (eccVec + trueToVec(trueAnomaly):NORMALIZED):NORMALIZED.
  }

  function vecToTrue {
    parameter vec.
    parameter pe is getPeriapsisVector().
    parameter normVec is NORMAL:VECTOR:NORMALIZED.

    local rotDir is VCRS(pe:NORMALIZED, normVec:NORMALIZED).

    if VANG(rotDir,vec)<90 {
      return VANG(pe:NORMALIZED, vec).
    } else {
      return 360-VANG(pe:NORMALIZED, vec).
    }
  }
  function vecToMean {
    parameter vec.
    parameter e is SHIP:ORBIT:ECCENTRICITY.

    return math["trueToMean"](vecToTrue(vec), e).
  }

  function trueToVec {
    parameter trueAnomaly.
    parameter pe is getPeriapsisVector().
    parameter normVec is NORMAL:VECTOR:NORMALIZED.
    parameter a is SHIP:ORBIT:SEMIMAJORAXIS.
    parameter e is SHIP:ORBIT:ECCENTRICITY.

    local rotDir is VCRS(pe, normVec:NORMALIZED).
    local vec is (pe * COS(trueAnomaly) + rotDir * SIN(trueAnomaly)):NORMALIZED.
    local length is math["radiusAtTrue"](trueAnomaly, a ,e).
    set vec:MAG to length.

    return vec.
  }

  function ascendingTrueAnomaly {
    parameter tgtnrml is -BODY:ANGULARVEL.

    local nodeDirection is vcrs(NORMAL:VECTOR:NORMALIZED, tgtnrml:NORMALIZED):NORMALIZED.
    return vecToTrue(nodeDirection).
  }

  function timeToTrue {
    parameter anomaly.
    parameter ecc is SHIP:ORBIT:ECCENTRICITY.
    parameter current is SHIP:ORBIT:MEANANOMALYATEPOCH.
    parameter p is 0.
    parameter e is SHIP:ORBIT:ECCENTRICITY.

    if p = 0 and e >= 1 {
      set p to ETA:PERIAPSIS * (360 / current).
    } else {
      set p to SHIP:ORBIT:PERIOD.
    }

    return timeToMean(math["trueToMean"](anomaly, ecc), current, p).
  }

  function timeToMean {
    parameter anomaly.
    parameter current is SHIP:ORBIT:MEANANOMALYATEPOCH.
    parameter p is 0.
    parameter e is SHIP:ORBIT:ECCENTRICITY.

    if p = 0 and e >= 1 {
      set p to ETA:PERIAPSIS * (360 / current).
    } else {
      set p to SHIP:ORBIT:PERIOD.
    }

    if p

    local t is p * anomaly / 360.
    local tt is  t - (p * current / 360).

    if tt < 0 {
      set tt to tt + p.
    }

    return tt.
  }

  function trueAtTime {
    parameter t.
    parameter period is SHIP:ORBIT:PERIOD.
    parameter currentTrue is SHIP:ORBIT:TRUEANOMALY.
    parameter tcurr is TIME:SECONDS.
    parameter eccentricity is SHIP:ORBIT:ECCENTRICITY.

    local dt is t-tcurr.
    local angle is dt/period * 360.
    return math["meanToTrue"](meanAtTime(t, period, currentTrue, tcurr), eccentricity).
  }
  function meanAtTime {
    parameter t.
    parameter period is SHIP:ORBIT:PERIOD.
    parameter currentTrue is SHIP:ORBIT:TRUEANOMALY.
    parameter tcurr is TIME:SECONDS.
    parameter eccentricity is SHIP:ORBIT:ECCENTRICITY.

    local dt is t-tcurr.
    local angle is dt/period * 360.
    return math["trueToMean"](currentTrue, eccentricity) + angle.
  }

  export(lex(
    "meanAtTime", meanAtTime@,
    "trueAtTime", trueAtTime@,
    "timeToTrue", timeToTrue@,
    "trueToVec", trueToVec@,
    "vecToTrue", vecToTrue@,
    "vecToMean", vecToMean@,
    "ascendingTrueAnomaly", ascendingTrueAnomaly@,
    "getEccentricityVector", getEccentricityVector@,
    "getPeriapsisVector", getPeriapsisVector@,
    "getOutVector", getOutVector@
  )).
}
