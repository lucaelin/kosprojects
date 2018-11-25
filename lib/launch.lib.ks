@lazyglobal off.
{
  local maneuver is import("lib/maneuver").
  local gui is import("lib/gui").

  local stagecontroller is false.
  local enginelist is LIST().
  LIST ENGINES IN enginelist.

  when stagecontroller = true and STAGE:NUMBER > 0 then {
    for e in enginelist {
      if e:FLAMEOUT {
        set stagecontroller to false.

        timeout({
          print "Stagecontroller event staging.".
          print e.
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
    LIST ENGINES IN enginelist.
    set stagecontroller to v.
  }.

  //*
  //* wait for a launchwindow to launch into the given target normal vector
  //* return a function that describes the required compass heading to match orbit with the targets normal
  //*
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
      return { return 90. }.
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

    local offsetTime is -30.
    local launchtime is TIME:SECONDS + offsetTime + (meanAtLowestInc + launchAngle)/360 * BODY:ROTATIONPERIOD.
    KUNIVERSE:TIMEWARP:WARPTO(launchtime - 10).
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

      return MAX(90 - tgtinc*COS(lng) + diff, -90).
    }.
  }

  //*
  //* Ascend vertially until a given speed is reached
  //* parameter speed is the desired speed
  //* parameter thrott is the throttle to use during this vertial climb
  //*
  function verticalAscend {
    parameter speed is 100.
    parameter thrott is 1.

    lock STEERING to UPTOP.
    lock THROTTLE to thrott.
    if SHIP:AVAILABLETHRUST = 0 {
      STAGE.
    }
    wait until SHIP:VELOCITY:SURFACE:MAG > speed.
  }.

  //*
  //* Ascend profile to launch into an orbit with a given height
  //* parameter height is the desired orbits altitude above sea level.
  //* parameter head is a function that describes the desired heading guidance. Such a function is returned by i.e. awaitLaunch.
  //*
  function gravitiyturn {
    parameter height is 85000.
    parameter head is {return 90.}.
    parameter profile is 0.

    set profile to 0.3 * profile.

    local guiCtx is gui["createContext"]("gravitiyturn").
    local logGui is guiCtx["log"].

    local turnStartAltitude is SHIP:ALTITUDE.
    lock STEERING to HEADING(
      head:CALL(),
      90-(90*(MAX(0, SHIP:ALTITUDE-turnStartAltitude)/(height-turnStartAltitude))^(0.5-profile))
    ).
    until APOAPSIS > height {
      logGui("Apoapsis", ROUND(APOAPSIS) + " / " + height).
      logGui("Periapsis", PERIAPSIS).
      logGui("Heading", head:CALL()).
      logGui("Horizontal angle", 90 - VANG(SHIP:UP:VECTOR, SHIP:FACING:FOREVECTOR)).
      logGui("Angle of attack", VANG(SHIP:ORBIT:VELOCITY:SURFACE, SHIP:FACING:FOREVECTOR)).
      wait 0.
    }
    lock THROTTLE to 0.

    guiCtx["remove"]().
  }.

  //*
  //* wait until the atm of the given body is completely below the ship
  //* TODO: consider using RCS to compensate losses due to drag
  //*
  function leaveATM {
    lock STEERING to SURFACEPROGRADE.
    wait until ALTITUDE > BODY:ATM:HEIGHT. // TODO: correct drag losses
    wait 1.
  }.

  //*
  //* function that launches the craft into a parking orbit of a given altitude having a given normal vector
  //* parameter alt is the desired parking orbits altitude
  //* parameter tgtnormal is the normal vector the parking orbit should try to have
  //*
  function launchTarget {
    parameter alt is 85000.
    parameter tgtnrml is -vcrs(TARGET:VELOCITY:ORBIT,BODY:POSITION-TARGET:POSITION).
    parameter turnStartSpeed is 100.
    parameter profile is 0.

    local guiCtx is gui["createContext"]("launch").
    local logGui is guiCtx["log"].

    local head is awaitLaunch(tgtnrml).
    setStagecontroller(true).
    logGui("Mode", "VASCEND").
    verticalAscend(turnStartSpeed).
    logGui("Mode", "GRAVITIYTURN").
    gravitiyturn(alt, head, profile).
    logGui("Mode", "COASTING OUT OF ATM").
    leaveATM().
    logGui("Mode", "CIRCULARIZE").
    maneuver["circularize"]().
    logGui("Mode", "ASCEND COMPLETE").
    print "ASCEND COMPLETE.".
    setStagecontroller(false).

    guiCtx["remove"]().
  }.

  //*
  //* function that launches the craft into a parking orbit of a given altitude
  //* parameter alt is the desired parking orbits altitude
  //* parameter head is a function to describe the desired compass heading during ascend
  //*
  function launch {
    parameter alt is 85000.
    parameter head is {return 90.}.
    parameter turnStartSpeed is 100.
    parameter profile is 0.

    local guiCtx is gui["createContext"]("launch").
    local logGui is guiCtx["log"].

    setStagecontroller(true).
    logGui("Mode", "VASCEND").
    verticalAscend(turnStartSpeed).
    logGui("Mode", "GRAVITIYTURN").
    gravitiyturn(alt, head, profile).
    logGui("Mode", "COASTING OUT OF ATM").
    leaveATM().
    logGui("Mode", "CIRCULARIZE").
    maneuver["circularize"]().
    logGui("Mode", "ASCEND COMPLETE").
    print "ASCEND COMPLETE.".
    setStagecontroller(false).
  }.

  export(lex(
    "setStagecontroller", setStagecontroller@,
    "awaitLaunch", awaitLaunch@,
    "verticalAscend", verticalAscend@,
    "gravitiyturn", gravitiyturn@,
    "leaveATM", leaveATM@,
    "launch", launch@,
    "launchTarget", launchTarget@
  )).
}
