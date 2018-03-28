{
  set SHIPNAME to SHIPNAME:SPLIT(" @ ")[0].

  local launch is import("lib/launch").
  local maneuver is import("lib/maneuver").
  local orbit is import("lib/orbit").

  lock STEERING to PROGRADE.

  local lan is 66.7.
  local inc is 41.1.
  local arg is 24.9.
  local apo is 30664600.
  local peri is 23329780.

  print "Adjusting inclination.".
  local ascendingVec is ANGLEAXIS(lan, BODY:ANGULARVEL) * SOLARPRIMEVECTOR.
  local tgtnrml is ANGLEAXIS(-inc,ascendingVec) * -BODY:ANGULARVEL.
  maneuver["adjustInclination"](tgtnrml).

  print "Circularizing again.".
  maneuver["circularize"]().

  print "Adjusting argument.".
  local argumentVec is ANGLEAXIS(arg, -tgtnrml) * orbit["trueToVec"](orbit["ascendingTrueAnomaly"]()).
  maneuver["adjustArgument"](argumentVec).

  print "Raising Apoapsis.".
  maneuver["raiseAp"](apo).

  wait 1.
  until STAGE:NUMBER = 0 {
    wait until STAGE:READY.
    stage.
    wait 1.
  }
  wait 1.

  print "Raising Periapsis.".
  maneuver["raisePe"](peri).


  print "Repeating all steps.".

  print "Adjusting inclination.".
  local ascendingVec is ANGLEAXIS(lan, BODY:ANGULARVEL) * SOLARPRIMEVECTOR.
  local tgtnrml is ANGLEAXIS(-inc,ascendingVec) * -BODY:ANGULARVEL.
  maneuver["adjustInclination"](tgtnrml).

  print "Adjusting argument.".
  local argumentVec is ANGLEAXIS(arg, -tgtnrml) * orbit["trueToVec"](orbit["ascendingTrueAnomaly"]()).
  maneuver["adjustArgument"](argumentVec).

  print "Raising Apoapsis.".
  maneuver["raiseAp"](apo).

  print "Raising Periapsis.".
  maneuver["raisePe"](peri).


  unlock STEERING.
  unlock THROTTLE.
  SAS on.
}
