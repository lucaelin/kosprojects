{
  local launch is import("lib/launch").

  when ALTITUDE > 55000 THEN {
    TOGGLE AG1.
    when ALTITUDE > 70000 THEN {
      TOGGLE AG2.
    }
  }

  local lan is 17.4.
  local inc is 42.
  local ascendingVec is ANGLEAXIS(lan, BODY:ANGULARVEL) * SOLARPRIMEVECTOR.
  local tgtnrml is ANGLEAXIS(-inc,ascendingVec) * -BODY:ANGULARVEL.
  launch["launchTarget"](95000, tgtnrml). // second stage twr is low while the first stage has a more fuel then needed

  set payload to PROCESSOR("payload").
  payload:CONNECTION:SENDMESSAGE("deploy").
}
