{
  local launch is import("lib/launch").
  local landing is import("lib/landing").
  local gui is import("lib/gui").

  function launchTarget {
    parameter alt is 85000.
    parameter tgtnrml is -vcrs(TARGET:VELOCITY:ORBIT,BODY:POSITION-TARGET:POSITION).

    local guiCtx is gui["createContext"]("launch").
    local logGui is guiCtx["log"].

    local head is launch["awaitLaunch"](tgtnrml).
    launch["setStagecontroller"](false).
    logGui("Mode", "VASCEND").
    launch["verticalAscend"]().
    logGui("Mode", "GRAVITIYTURN").
    launch["gravitiyturn"](alt, head).
    guiCtx["remove"]().
    logGui("Mode", "COASTING OUT OF ATM").
    launch["leaveATM"]().
  }.

  when ALTITUDE > 55000 THEN {
    TOGGLE AG1.
    when ALTITUDE > 70000 THEN {
      TOGGLE AG2.
    }
  }

  launchTarget(95000, -BODY:ANGULARVEL). // second stage twr is low while the first stage has a more fuel then needed

  lock STEERING to LOOKDIRUP((-SHIP:ORBIT:VELOCITY:SURFACE:NORMALIZED) + (SHIP:UP:VECTOR / 4), SHIP:FACING:TOPVECTOR).

  wait until ALTITUDE < SHIP:BODY:ATM:HEIGHT.
  RCS on.
  wait until ALT:RADAR < 7000.
  lock THROTTLE to 1.
  wait until SHIP:ORBIT:VELOCITY:SURFACE:MAG < 300.
  lock THROTTLE to 0.
  when ALTITUDE < 1000 THEN {
    GEAR on.
  }

  RCS off.
  local tgt is "somewhere".
  local thrott is 0.9.
  local height is 30.
  local AoA is 15.
  local hThrott is 2.
  local lookahead is 2.
  local bodylift is true.
  local ttiMult is 1.

  landing["land"](tgt, thrott, height, AoA, hThrott, lookahead, bodylift, ttiMult).

  set payload to PROCESSOR("payload").
  payload:CONNECTION:SENDMESSAGE("deploy").
}
