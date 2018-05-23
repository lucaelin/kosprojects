@lazyglobal off.
{
  //*
  //* This class provides background functionality running without blocking execution
  //* usually there are two functions one to enable the feature and one to disable it again
  //*


  // Automatic staging
  local stagecontrollerActive is false.

  //*
  //* A controller to automatically stage the craft if there are active engines without any fuel left.
  //*
  function staging {
    set stagecontrollerActive to true.

    local enginelist is LIST().
    LIST ENGINES IN enginelist.

    local tempDisabled is false.

    on TIME:SECONDS {
      if not tempDisabled {
        for e in enginelist {
          if e:FLAMEOUT {
            set tempDisabled to true.

            timeout({
              STAGE.
              timeout({
                LIST ENGINES IN enginelist.
                set tempDisabled to false.
              }).
            }).

            BREAK.
          }
        }
      }
      if stagecontrollerActive and STAGE:NUMBER > 0 {PRESERVE.}
    }
  }.

  function disableStaging {
    set stagecontrollerActive to false.
  }

  //*
  //* Ascend and descend vertical speed controller, adjusting the throttle not the orientation
  //* parameter targetspeed is a function that needs to return the desired vertical speed
  //* parameter kP describes how aggressively the engine should change its throttle to match the velocity
  //*
  local vSpeedActive is false.

  function vSpeed {
    parameter targetspeed is { return 0. }.
    parameter kP is 10.

    set vSpeedActive to true.
    local state is LEX().

    local thrott is 0.
    lock THROTTLE to CLAMP(0,1, thrott).

    on TIME:SECONDS {
      //CLEARSCREEN.

      local acc is VDOT(SHIP:UP:VECTOR, SHIP:FACING:VECTOR) * SHIP:AVAILABLETHRUST / SHIP:MASS.
      //print "acc: " + acc at(0,0).
      local g is BODY:MU / BODY:RADIUS^2.
      //print "  g: " + g at(0,1).
      local avgThrottle to g / acc.
      //print "avg: " + avgThrottle at(0,2).
      local error is (SHIP:VERTICALSPEED - targetSpeed()) / acc.
      //print "err: " + error at(0,4).
      set thrott to avgThrottle - error*kP.

      if vspeedactive {PRESERVE.}
    }

    return state.
  }
  function disableVSpeed {
    set vSpeedActive to false.
    unlock THROTTLE.
  }


  //*
  //* Horizontal speed controller, not adjusting the throttle but the orientation
  //* The function hSpeedInvert can be used to invert the steering (for use with i.e. bodylift)
  //* parameter targetVelParam is a function that needs to return a vector for the direction to move in with its magitude to describe the speed
  //* parameter minThrottle describes the average throttle that is expected
  //* parameter lookahead describes the time in seconds the system should look ahead of its current state to make predictive decisions
  //* parameter Klimit is the highest horizontal acceleration the system should use to match the given velocity
  //* parameter kP describes how aggressively the engine should change its throttle to match the velocity
  //*
  local hSpeedActive is false.
  local hSpeedInverted is false.

  function hSpeed {
    parameter targetVelParam is { return 0. }.
    parameter minThrottle is 0.1.
    parameter lookahead is 0.
    parameter Klimit is 8.
    parameter Kp is 10.

    set hSpeedActive to true.
    local state is LEX().

    local targetVelFn is { return VXCL(SHIP:UP:VECTOR, targetVelParam()). }.

    local steer is UPTOP:VECTOR.
    lock STEERING to LOOKDIRUP(steer, SHIP:FACING:TOPVECTOR).

    on TIME:SECONDS {
      CLEARVECDRAWS().

      local maxAcc is SHIP:AVAILABLETHRUST / SHIP:MASS.
      local avgAcc is maxAcc * minThrottle.
      local currAcc is maxAcc * THROTTLE.

      local targetVelVec to targetVelFn().
      VECDRAW(V(0,0,0), targetVelVec, green, "targetVel", 1, true, .2).
      local velVec is VXCL(SHIP:UP:VECTOR, SHIP:VELOCITY:SURFACE).
      VECDRAW(V(0,0,0), velVec, red, "vel", 1, true, .2).

      local rot is SHIP:ANGULARVEL * lookahead / 2.
      local accVec is VXCL(SHIP:UP:VECTOR, ANGLEAXIS(rot:MAG * RADTODEG, rot) * SHIP:FACING:VECTOR) * MAX(avgAcc, currAcc).
      if hSpeedInverted {
        set accVec to -accVec.
      }
      VECDRAW(velVec, lookahead*accVec, blue, "acc", 1, true, .2).

      local velError is targetVelVec - (velVec + lookahead*accVec).
      local targetAccVec is velError:NORMALIZED * clamp(-Klimit, Klimit, velError:MAG * 10).


      //local state is (targetAccVec / avgAcc)/SQRT(MAX(0.1,1-(targetAccVec:MAG / avgAcc)^2)).
      local hAccVec is targetAccVec.
      //print maxAcc * minThrottle.
      //print targetAccVec:MAG.
      //local vAccVec is SHIP:UP:VECTOR * SQRT((maxAcc * minThrottle)^2 - targetAccVec:MAG^2).
      local vAccVec is SHIP:UP:VECTOR * maxAcc * minThrottle.

      if hSpeedInverted {
        set hAccVec to -hAccVec.
      }
      set steer to vAccVec + hAccVec.//topSteer + starSteer.
      //print VANG(STEER,targetVelVec).
      VECDRAW(V(0,0,0), steer, yellow, "steer", 10, true, .02).
      //VECDRAW(10*UPTOP:VECTOR, topSteer, green, "steerTop", 10, true, .02).
      //VECDRAW(10*UPTOP:VECTOR, starSteer, yellow, "steerStar", 10, true, .02).

      if hspeedactive {PRESERVE.}
    }

    return state.
  }
  function hSpeedInvert {
    parameter val is true.
    set hSpeedInverted to val.
  }
  function disableHSpeed {
    set hSpeedActive to false.
    unlock STEERING.
  }

  export(lex(
    "vSpeed", vSpeed@,
    "disableVSpeed", disableVSpeed@,
    "hSpeed", hSpeed@,
    "hSpeedInvert", hSpeedInvert@,
    "disableHSpeed", disableHSpeed@,
    "staging", staging@,
    "disableStaging", disableStaging@
  )).
}
