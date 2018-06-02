@lazyglobal off.
{
  local trigon is import("lib/trigonometry").

  function periodToAxis {
    parameter period.
    parameter mu is BODY:MU.

    return ((period / (2 * CONSTANT:PI)) ^ 2 * mu) ^ (1 / 3).
  }
  function orbitalPhasing {
    parameter a.
    parameter b.

    return -(360 / b - 360 / a) * a.
  }
  function diffAnomaly {
    parameter a.
    parameter b.

    until a < b {
      set a to a-360.
    }
    return b-a.
  }
  function eccToTrue {
    parameter eccAnomaly.
    parameter eccentricity is SHIP:ORBIT:ECCENTRICITY.

    if eccentricity > 1 return ARCTAN(SQRT((eccentricity + 1) / (eccentricity - 1)) * trigon["tanh"](eccAnomaly / 2)) * 2.

    local halforbits is FLOOR(eccAnomaly/180).
    set eccAnomaly to MODMOD(eccAnomaly, 360).
    local invert is MOD(halforbits, 2) * (-2) + 1.
    return 360 * FLOOR(halforbits/2) + MOD(invert * ARCTAN(SQRT((1 + eccentricity) / (1 - eccentricity)) * TAN(eccAnomaly / 2)) * 2 + 360, 360).
  }
  function trueToEcc {
    parameter trueAnomaly.
    parameter eccentricity is SHIP:ORBIT:ECCENTRICITY.

    if eccentricity > 1 return trigon["arcosh"]((eccentricity + COS(trueAnomaly)) / (1 + eccentricity * COS(trueAnomaly))).

    local halforbits is FLOOR(trueAnomaly/180).
    set trueAnomaly to MODMOD(trueanomaly, 360).
    local invert is MOD(halforbits, 2) * (-2) + 1.
    return 360 * FLOOR(halforbits/2) + MOD(invert * ARCCOS((eccentricity + COS(trueAnomaly)) / (1 + eccentricity * COS(trueAnomaly))) + 360, 360).
  }
  function eccToMean {
    parameter eccentricAnomaly.
    parameter eccentricity is SHIP:ORBIT:ECCENTRICITY.

    if eccentricity > 1 return eccentricity * trigon["sinh"](eccentricAnomaly) * RADTODEG - eccentricAnomaly.
    local m is floor(eccentricAnomaly/360).
    set eccentricAnomaly to mod(eccentricAnomaly, 360).

    return m * 360 + eccentricAnomaly - (eccentricity * SIN(eccentricAnomaly)) * (180 / constant:pi).
  }
  function trueToMean {
    parameter trueAnomaly.
    parameter eccentricity is SHIP:ORBIT:ECCENTRICITY.

    return eccToMean(trueToEcc(trueAnomaly, eccentricity), eccentricity).
  }
  function meanToTrue {
    parameter meanAnomaly.
    parameter eccentricity is SHIP:ORBIT:ECCENTRICITY.

    local m is floor(meanAnomaly/360).
    set meanAnomaly to mod(meanAnomaly, 360).
    if eccentricity > 0.25 {
      print "The use of meanToTrue might be signifficantly off in this Orbit!".
    }

    return 360 * m + meanAnomaly + (2 * eccentricity * SIN(meanAnomaly) * (180 / constant:pi) + 1.25 * eccentricity ^ 2 * SIN(2*meanAnomaly) * (180 / constant:pi)).
  }

  function radiusAtTrue {
    parameter anomaly.
    parameter a is SHIP:ORBIT:SEMIMAJORAXIS.
    parameter e is SHIP:ORBIT:ECCENTRICITY.

    return radiusAtEcc(trueToEcc(anomaly, e), a, e).
  }
  function radiusAtEcc {
    parameter eAnomaly.
    parameter a is SHIP:ORBIT:SEMIMAJORAXIS.
    parameter e is SHIP:ORBIT:ECCENTRICITY.

    return a * (1 - e * COS(eAnomaly)).
  }

  function trueAtRadius {
    parameter radius.
    parameter a is SHIP:ORBIT:SEMIMAJORAXIS.
    parameter e is SHIP:ORBIT:ECCENTRICITY.

    return eccToTrue(eccAtRadius(radius, a, e), e).
  }
  function eccAtRadius {
    parameter radius.
    parameter a is SHIP:ORBIT:SEMIMAJORAXIS.
    parameter e is SHIP:ORBIT:ECCENTRICITY.

    if e > 1 {
        return trigon["arcosh"]((a - radius)/(e * a)).
    }
    return ARCCOS((a - radius)/(e * a)).
  }

  function velAtTrue {
    parameter anomaly.
    parameter a is SHIP:ORBIT:SEMIMAJORAXIS.
    parameter e is SHIP:ORBIT:ECCENTRICITY.
    parameter mu is BODY:MU.

    return velAtRadius(radiusAtTrue(anomaly, a, e), a, mu).
  }
  function velAtRadius {
    parameter radius.
    parameter a is SHIP:ORBIT:SEMIMAJORAXIS.
    parameter mu is BODY:MU.

    return SQRT(mu * ((2 / radius) - (1 / a))).
  }

  function storeVector {
    parameter vec.
    parameter spv is SOLARPRIMEVECTOR.

    return V( vec:x * spv:x + vec:z * spv:z, vec:z * spv:x - vec:x * spv:z, vec:y).
  }
  function loadVector {
    parameter p.
    parameter spv is SOLARPRIMEVECTOR.

    return V( p:x * spv:x - p:y * spv:z, p:z, p:x * spv:z + p:y * spv:x ).
  }

  export(lex(
    "orbitalPhasing", orbitalPhasing@,
    "diffAnomaly", diffAnomaly@,
    "eccToTrue", eccToTrue@,
    "trueToEcc", trueToEcc@,
    "eccToMean", eccToMean@,
    "trueToMean", trueToMean@,
    "meanToTrue", meanToTrue@,
    "radiusAtTrue", radiusAtTrue@,
    "radiusAtEcc", radiusAtEcc@,
    "trueAtRadius", trueAtRadius@,
    "eccAtRadius", eccAtRadius@,
    "velAtTrue", velAtTrue@,
    "velAtRadius", velAtRadius@,
    "storeVector", storeVector@,
    "loadVector", loadVector@
  )).
}
