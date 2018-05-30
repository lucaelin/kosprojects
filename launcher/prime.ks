{
  local launch is import("lib/launch").

  when ALTITUDE > 55000 THEN {
    TOGGLE AG1.
    when ALTITUDE > 70000 THEN {
      TOGGLE AG2.
    }
  }

  local tgt is recvMsg().

  local lan is tgt["LAN"].
  local inc is tgt["INC"].
  local ascendingVec is ANGLEAXIS(lan, BODY:ANGULARVEL) * SOLARPRIMEVECTOR.
  local tgtnrml is ANGLEAXIS(-inc,ascendingVec) * -BODY:ANGULARVEL.
  launch["launchTarget"](85000, tgtnrml).

  set payload to PROCESSOR("payload").
  payload:CONNECTION:SENDMESSAGE("deploy").
}
