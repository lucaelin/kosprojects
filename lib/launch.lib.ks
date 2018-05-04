@lazyglobal off.
{
  local maneuver is import("lib/maneuver").

  local stagecontroller is false.
  local enginelist is LIST().
  LIST ENGINES IN enginelist.

  when stagecontroller = true and STAGE:NUMBER > 0 then {
    for e in enginelist {
      if e:FLAMEOUT {
        set stagecontroller to false.

        timeout({
          STAGE.
          timeout({
            LIST ENGINES IN enginelist.
            set stagecontroller to true.
          }).
        }).

        BREAK.
      }
    }
    PRESERVE.
  }

  function setStagecontroller {
    parameter v is true.
    set stagecontroller to v.
  }.

  function awaitLaunch {
    parameter tgtnrml is -vcrs(TARGET:VELOCITY:ORBIT,BODY:POSITION-TARGET:POSITION).

    local ascendingVec is vcrs(tgtnrml, -BODY:ANGULARVEL).
    local inc is VANG(tgtnrml, -BODY:ANGULARVEL).
    local myinc is VANG(-BODY:ANGULARVEL, NORMAL:VECTOR).

    print "Awaiting launch window.".

    local currentHead is VXCL(-BODY:ANGULARVEL:NORMALIZED, NORMAL:VECTOR).

    local tgtHead is VXCL(-BODY:ANGULARVEL:NORMALIZED, tgtnrml).

    if VANG(-BODY:ANGULARVEL:NORMALIZED, tgtnrml) < 1 {
      print "Target is almost equatorial. Launching now.".
      return 0.
    }

    local meanAtLowestInc is VANG(currentHead, tgtHead).

    if VDOT(SHIP:VELOCITY:ORBIT, tgtHead) > 0 {
      set meanAtLowestInc to 360-meanAtLowestInc.
    }

    local myinc is VANG(-BODY:ANGULARVEL, NORMAL:VECTOR).
    local tgtinc is VANG(-BODY:ANGULARVEL, tgtnrml).
    local launchAngle is 0.
    if (myinc<tgtinc) {
      print "Instantaneous window found.".
      set launchAngle to 90-ARCSIN(myinc/inc).
      print "launchAngle: " + launchAngle.
    } else {
      print "Target has a low inclination. Lauching at lowest relative inclination.".
    }

    local launchtime is TIME:SECONDS + (meanAtLowestInc + launchAngle)/360 * BODY:ROTATIONPERIOD.
    KUNIVERSE:TIMEWARP:WARPTO(launchtime).
    wait until TIME:SECONDS > launchtime.
    wait until KUNIVERSE:TIMEWARP:ISSETTLED.
    wait 1.

    print myinc + " " + tgtinc + " ".
    local lng is 180-ARCSIN(MIN(myinc/tgtinc, 1)).
    local launchinc is tgtinc*COS(lng).

    print "Launching now at "+launchinc+"°.".

    return {
      local myinc is VANG(-BODY:ANGULARVEL, NORMAL:VECTOR).
      local tgtinc is VANG(-BODY:ANGULARVEL, tgtnrml).
      local diff is tgtinc - myinc.
      local lng is 180-ARCSIN(MIN(SHIP:GEOPOSITION:LAT/tgtinc, 1)).
      if diff > 90 {
        set diff to diff - 180.
        print "TODO: test".
      }
      return 90 - tgtinc*COS(lng) + diff.
    }.
  }

  function verticalAscend {
    parameter speed is 100.
    parameter thrott is 1.

    lock STEERING to UPTOP.
    lock THROTTLE to thrott.
    STAGE.
    wait until SHIP:VELOCITY:SURFACE:MAG > speed.
  }.

  function gravitiyturn {
    parameter height is 85000.
    parameter head is {return 90.}.

    local turnStartAltitude is SHIP:ALTITUDE.
    lock STEERING to HEADING(head:CALL(), 90-(90*SQRT((SHIP:ALTITUDE-turnStartAltitude)/(height-turnStartAltitude)))).
    wait until APOAPSIS > height.
    lock THROTTLE to 0.
  }.

  function leaveATM {
    wait until ALTITUDE > BODY:ATM:HEIGHT. // TODO: correct drag losses
    wait 1.
  }.

  function launchTarget {
    parameter alt is 85000.
    parameter tgtnrml is -vcrs(TARGET:VELOCITY:ORBIT,BODY:POSITION-TARGET:POSITION).

    local head is awaitLaunch(tgtnrml).
    setStagecontroller(true).
    print "VASCEND.".
    verticalAscend().
    print "GRAVITIYTURN.".
    gravitiyturn(alt, head).
    print "COASTING OUT OF ATM.".
    leaveATM().
    print "CIRCULARIZE.".
    maneuver["circularize"]().
    print "ASCEND COMPLETE.".
    setStagecontroller(false).
  }.
  function launch {
    parameter alt is 85000.
    parameter head is {return 90.}.
    setStagecontroller(true).
    print "VASCEND.".
    verticalAscend().
    print "GRAVITIYTURN.".
    gravitiyturn(alt, head).
    print "COASTING OUT OF ATM.".
    leaveATM().
    print "CIRCULARIZE.".
    maneuver["circularize"]().
    print "ASCEND COMPLETE.".
    setStagecontroller(false).
  }.

  export(lex(
    "setStagecontroller", setStagecontroller@,
    "verticalAscend", verticalAscend@,
    "gravitiyturn", gravitiyturn@,
    "leaveATM", leaveATM@,
    "launch", launch@,
    "launchTarget", launchTarget@
  )).
}
