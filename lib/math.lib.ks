@lazyglobal off.
{
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

    // TODO: correction for mutiple orbit passes.
    if a > b {
      set a to a-360.
    }
    return b-a.
  }
  function eccToTrue {
    parameter eccAnomaly.
    parameter eccentricity is SHIP:ORBIT:ECCENTRICITY.

    local m is floor(eccAnomaly/360).
    set eccAnomaly to mod(eccAnomaly, 360).

    return m * 360 + 2 * ARCTAN2(SQRT(1 + eccentricity) * SIN(eccAnomaly / 2), SQRT(1 - eccentricity) * COS(eccAnomaly / 2)).
  }
  function trueToEcc {
    parameter trueAnomaly.
    parameter eccentricity is SHIP:ORBIT:ECCENTRICITY.

    local eccAnom is 2 * ARCTAN(SQRT((1 - eccentricity) / (1 + eccentricity)) * TAN(trueAnomaly / 2)).
    local m is floor(trueAnomaly/360).
    set trueAnomaly to mod(trueAnomaly, 360).

    // TODO: make correct for more than 180
    if trueAnomaly > 180 {
      return m * 360 + 360 + eccAnom.
    }
    return m * 360 + eccAnom.
  }
  function eccToMean {
    parameter eccentricAnomaly.
    parameter eccentricity is SHIP:ORBIT:ECCENTRICITY.

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

  function velAtTrue {
    parameter anomaly.
    parameter a is SHIP:ORBIT:SEMIMAJORAXIS.
    parameter e is SHIP:ORBIT:ECCENTRICITY.
    parameter mu is BODY:MU.

    return velAtRadius(radiusAtTrue(anomaly), a, mu).
  }
  function velAtRadius {
    parameter radius.
    parameter a is SHIP:ORBIT:SEMIMAJORAXIS.
    parameter mu is BODY:MU.

    return SQRT(mu * ((2 / radius) - (1 / a))).
  }

  function storeVector {
    parameter vec.
    return lex(
      "dir", ROTATEFROMTO(SOLARPRIMEVECTOR, vec),
      "mag", vec:MAG
    ).
  }
  function loadVector {
    parameter p.
    local vec is p["dir"]*SOLARPRIMEVECTOR.
    set vec:MAG to p["mag"].
    return vec.
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
    "velAtTrue", velAtTrue@,
    "velAtRadius", velAtRadius@,
    "storeVector", storeVector@,
    "loadVector", loadVector@
  )).
}
