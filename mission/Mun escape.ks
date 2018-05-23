{
  local maneuver is import("lib/maneuver").
  local math is import("lib/math").

  wait 0.
  stage.
  wait until STAGE:READY.

  //maneuver["raiseAt"](90, 500000). //TODO: test
  local excess is 200.
  local angle is 180.
//  maneuver["escape"](excess, angle).
  until false {
    print math["eccAtRadius"](BODY:SOIRADIUS, SHIP:ORBIT:SEMIMAJORAXIS, SHIP:ORBIT:ECCENTRICITY) at(1,10).
    print math["eccAtRadius"](BODY:RADIUS+ALTITUDE, SHIP:ORBIT:SEMIMAJORAXIS, SHIP:ORBIT:ECCENTRICITY) at(1,11).
    print math["trueAtRadius"](BODY:SOIRADIUS, SHIP:ORBIT:SEMIMAJORAXIS, SHIP:ORBIT:ECCENTRICITY) at(1,13).
    print math["trueAtRadius"](BODY:RADIUS+ALTITUDE, SHIP:ORBIT:SEMIMAJORAXIS, SHIP:ORBIT:ECCENTRICITY) at(1,14).
    //print math["trueAtRadius"](BODY:SOIRADIUS, SHIP:ORBIT:SEMIMAJORAXIS, SHIP:ORBIT:ECCENTRICITY) at(1,11).
    wait 0.
  }
}
