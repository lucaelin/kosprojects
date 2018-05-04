@lazyglobal off.
{
  // Automatic staging
  local stagecontrollerActive is false.

  function staging {
    parameter v is true.
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

  // Ascend and descend vertical speed controller
  local vSpeedActive is false.

  function vSpeed {
    parameter targetspeed is { return 0. }.
    parameter kP is 10.

    set vSpeedActive to true.
    local thrott is 1.
    lock THROTTLE to thrott.

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
  }
  function disableVSpeed {
    set vSpeedActive to false.
  }

  //horizontal speed controller
  local hSpeedActive is false.

  function hSpeed {
    parameter targetVelParam is { return 0. }.
    parameter minThrottle is 0.1.
    parameter lookahead is 0.
    parameter Klimit is 8. // TODO: craft specific
    parameter Kp is 0.3.
    parameter Ki is 0.0.
    parameter Kd is 0.2.

    set hSpeedActive to true.
    local targetVelFn is { return VXCL(SHIP:UP:VECTOR, targetVelParam()). }.

    local steer is UPTOP:VECTOR.
    local steercorr is V(0,0,0).
    lock STEERING to LOOKDIRUP(steer + steercorr, SHIP:FACING:TOPVECTOR).

    local velPID is PIDLOOP(Kp, Ki, Kd).
    set velPID:MINOUTPUT to -Klimit.
    set velPID:MAXOUTPUT to Klimit.
    local accPID is PIDLOOP(10.0, 0, 10.0).
    //set accPID:MINOUTPUT to -1.
    //set accPID:MAXOUTPUT to 1.
    //local topPID is PIDLOOP(Kp, Ki, Kd).
    //set topPID:MINOUTPUT to -Klimit.
    //set topPID:MAXOUTPUT to Klimit.
    //local starPID is PIDLOOP(Kp, Ki, Kd).
    //set starPID:MINOUTPUT to -Klimit.
    //set starPID:MAXOUTPUT to Klimit.

    on TIME:SECONDS {
      CLEARSCREEN.
      CLEARVECDRAWS().

      local hTop is VXCL(SHIP:FACING:STARVECTOR, VXCL(SHIP:UP:VECTOR, SHIP:FACING:TOPVECTOR)):NORMALIZED.
      local hStar is VXCL(SHIP:FACING:TOPVECTOR, VXCL(SHIP:UP:VECTOR, SHIP:FACING:STARVECTOR)):NORMALIZED.
      local acc is SHIP:AVAILABLETHRUST * minThrottle / SHIP:MASS.

      local targetVelVec to targetVelFn().
      VECDRAW(V(0,0,0), targetVelVec, green, "targetVel", 1, true, .2).
      local velVec is VXCL(SHIP:UP:VECTOR, SHIP:VELOCITY:SURFACE).
      VECDRAW(V(0,0,0), velVec, red, "vel", 1, true, .2).
      //local targetTopVel is VDOT(hTop, targetVelVec).
      //print " tTopVel: " + targetTopVel at(0,1).
      //local targetStarVel is VDOT(hStar, targetVelVec).
      //print "tStarVel: " + targetStarVel at(0,2).
      //local topVel is VDOT(hTop, velVec).
      //print " topVel: " + topVel at(0,4).
      //local starVel is VDOT(hStar, velVec).
      //print "starVel: " + starVel at(0,5).
      //local topVelError is targetTopVel - topVel.
      //local starVelError is targetStarVel - starVel.

      local rot is SHIP:ANGULARVEL * lookahead / 2.
      local accVec is VXCL(SHIP:UP:VECTOR, ANGLEAXIS(rot:MAG * RADTODEG, rot) * SHIP:FACING:VECTOR) * acc.
      VECDRAW(velVec, lookahead*accVec, blue, "acc", 1, true, .2).
      local velError is targetVelVec - (velVec+lookahead*accVec).
      local targetAccVec is velError:NORMALIZED * velPID:UPDATE(TIME:SECONDS, -velError:MAG).

      //local targetTopAcc is topPID:UPDATE(TIME:SECONDS, -topVelError).
      //print " tTopAcc: " + targetTopAcc at(0,7).
      //local targetStarAcc is starPID:UPDATE(TIME:SECONDS, -starVelError).
      //print "tStarAcc: " + targetStarAcc at(0,8).

      //local accVec is VXCL(SHIP:UP:VECTOR, SURFACEPROGRADE:VECTOR).
      local accVec is VXCL(SHIP:UP:VECTOR, SHIP:FACING:VECTOR) * SHIP:AVAILABLETHRUST * THROTTLE / SHIP:MASS.
      //local topAcc is VDOT(hTop, SHIP:FACING:VECTOR) * SHIP:AVAILABLETHRUST * THROTTLE / SHIP:MASS.
      //print " topAcc: " + topAcc at(0,10).
      //local starAcc is VDOT(hStar, SHIP:FACING:VECTOR) * SHIP:AVAILABLETHRUST * THROTTLE / SHIP:MASS.
      //print "starAcc: " + starAcc at(0,11).
      //local topSpeed is VDOT(hTop, speedVec).
      //print " topSpeed: " + topSpeed at(0,7).
      //local starSpeed is VDOT(hStar, speedVec).
      //print "starSpeed: " + starSpeed at(0,8).

      //local topError is (targetTopAcc - topAcc) / acc.// / topAcc.
      //print " topError: " + topError at(0,13).
      //local starError is (targetStarAcc - starAcc) / acc.// / starAcc.
      //print "starError: " + starError at(0,14).

      //local accErrorVec is targetAccVec - accVec.
      local accErrorVec is VXCL(SHIP:FACING:VECTOR, steer:NORMALIZED).
      local accCorrVec is accErrorVec:NORMALIZED * accPID:UPDATE(TIME:SECONDS, -accErrorVec:MAG).

      local state is (targetAccVec / acc)/SQRT(MAX(0.1,1-(targetAccVec:MAG / acc)^2)).
      local corr is (accCorrVec / acc)/SQRT(MAX(0,1-(accCorrVec:MAG / acc)^2)).
      //local topState is (targetTopAcc / acc)/SQRT(MAX(0.1,1-(ABS(targetTopAcc) / acc)^2)).
      //local topSteer is hTop * (topState + topError * Kp).
      //local starState is (targetStarAcc / acc)/SQRT(MAX(0.1,1-(ABS(targetStarAcc) / acc)^2)).
      //local starSteer is hStar * (starState + starError * Kp).

      set steer to SHIP:UP:VECTOR + state.//topSteer + starSteer.
      //set steerCorr to corr.
      VECDRAW(10*UPTOP:VECTOR, state, yellow, "steer", 10, true, .02).
      VECDRAW(10*UPTOP:VECTOR + 10*state, corr, green, "corr", 10, true, .02).
      //VECDRAW(10*UPTOP:VECTOR, topSteer, green, "steerTop", 10, true, .02).
      //VECDRAW(10*UPTOP:VECTOR, starSteer, yellow, "steerStar", 10, true, .02).
      //VECDRAW(10*UPTOP:VECTOR, hTop * topError, green, "steerTop", 10, true, .02).
      //VECDRAW(10*UPTOP:VECTOR, hStar * starError, yellow, "steerStar", 10, true, .02).

      if hspeedactive {PRESERVE.}
    }
  }
  function disableHSpeed {
    set hSpeedActive to false.
  }

  export(lex(
    "vSpeed", vSpeed@,
    "disableVSpeed", disableVSpeed@,
    "hSpeed", hSpeed@,
    "disableHSpeed", disableHSpeed@,
    "staging", staging@,
    "disableStaging", disableStaging@
  )).
}
