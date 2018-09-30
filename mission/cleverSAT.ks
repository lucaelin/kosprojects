{
  local launch is import("lib/launch").
  local maneuver is import("lib/maneuver").
  local orbit is import("lib/orbit").

  local lan is 0.
  local inc is 90.
  local arg is 0.
  local apo is 250000.
  local peri is 250000.

  local obt is LEX(
    "LAN", lan,
    "INC", inc,
    //"ARG", arg,
    "AP", apo,
    "PE", peri
  ).

  local launcher to PROCESSOR("launcher").
  launcher:CONNECTION:SENDMESSAGE(obt).

  recvMsg().
  set SHIPNAME to SHIPNAME:SPLIT(" @ ")[0].

  lock STEERING to PROGRADE.

  print "Adjusting inclination.".
  local ascendingVec is ANGLEAXIS(lan, BODY:ANGULARVEL) * SOLARPRIMEVECTOR.
  local tgtnrml is ANGLEAXIS(-inc,ascendingVec) * -BODY:ANGULARVEL.
  maneuver["adjustInclination"](tgtnrml).

  print "Circularizing again.".
  maneuver["circularize"]().

  if obt:HASKEY("ARG") {
    print "Adjusting argument.".
    local argumentVec is ANGLEAXIS(arg, -tgtnrml) * orbit["trueToVec"](orbit["ascendingTrueAnomaly"]()).
    maneuver["adjustArgument"](argumentVec).
  }

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

  if obt:HASKEY("ARG") {
    print "Adjusting argument.".
    local argumentVec is ANGLEAXIS(arg, -tgtnrml) * orbit["trueToVec"](orbit["ascendingTrueAnomaly"]()).
    maneuver["adjustArgument"](argumentVec).
  }

  print "Raising Apoapsis.".
  maneuver["raiseAp"](apo).

  print "Raising Periapsis.".
  maneuver["raisePe"](peri).


  unlock STEERING.
  unlock THROTTLE.
  SAS on.
}
