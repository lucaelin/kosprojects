@lazyglobal off.
{
  function tgtPrograde {
    parameter tgt is TARGET.
    return LOOKDIRUP(-(tgt:VELOCITY:ORBIT - SHIP:VELOCITY:ORBIT), SHIP:FACING:TOPVECTOR).
  }
  function tgtRetrograde {
    parameter tgt is TARGET.
    return LOOKDIRUP(tgt:VELOCITY:ORBIT - SHIP:VELOCITY:ORBIT, SHIP:FACING:TOPVECTOR).
  }
  function rendezvous {
    parameter tgt is TARGET.
    parameter closeDist is 5000.

    lock STEERING to tgtRetrograde(tgt).

    print "Awaiting close approach.".
    local closeanomaly is math["trueAtRadius"](BODY:RADIUS + tgt:ORBIT:PERIAPSIS - 5000).
    local closetime is orbit["timeToTrue"](closeanomaly).
    KUNIVERSE:TIMEWARP:WARPTO(TIME:SECONDS + closetime).
    wait until KUNIVERSE:TIMEWARP:ISSETTLED.

    wait until tgt:POSITION:MAG < closeDist.

    print "Killing relative velocity.".

    lock THROTTLE to 1.
    wait until (tgt:VELOCITY:ORBIT - SHIP:VELOCITY:ORBIT):MAG < (SHIP:AVAILABLETHRUST / SHIP:MASS) / 2.
    lock THROTTLE to 0.
  }
  function dock {
    parameter porttag is "".
    parameter tgt is TARGET.
    RCS on.
    lock STEERING to tgt:FACING.

    print "Closing in on target.".
    until tgt:POSITION:MAG < 1000 {
      steer(tgt:POSITION / 100).
    }
    print "Closing in on 100m hold.".
    until tgt:POSITION:MAG < 100 {
      steer((tgt:POSITION - tgt:POSITION:NORMALIZED * 90) / 15, 5).
    }

    local port is SHIP:DOCKINGPORTS[0].
    for p in SHIP:DOCKINGPORTS {
      if p:STATE = "Ready" {
        set port to p.
      }
    }
    local tgtports is tgt:DOCKINGPORTS:ITERATOR.
    local tgtport is tgt:DOCKINGPORTS[0].
    until not tgtports:NEXT and not porttag {
      if tgtports:VALUE:NODETYPE = port:NODETYPE and tgtports:VALUE:STATE = "Ready" {
        set tgtport to tgtports:VALUE.
        if porttag:LENGTH > 0 and porttag = tgtport:TAG {break.}
        if porttag:LENGTH = 0 and port:TAG:LENGTH > 0 and port:TAG = tgtport:TAG {break.}
      }
    }.

    set TARGET to tgtport.
    wait 0.
    lock STEERING to LOOKDIRUP(-tgtport:PORTFACING:FOREVECTOR, tgtport:PORTFACING:TOPVECTOR).

    // TODO: make positons relative to port:NODEPOSITION

    print "Moving towards port alignment.".
    until VANG(tgtport:NODEPOSITION, -tgtport:PORTFACING:FOREVECTOR) < 5 {
      local dist is (tgtport:NODEPOSITION - tgtport:NODEPOSITION:NORMALIZED * 90) / 5.
      steer(VXCL(tgtport:NODEPOSITION, tgtport:PORTFACING:FOREVECTOR) + dist, 2, tgt).
    }
    print "Moving towards port.".
    until tgtport:STATE = "PreAttached" or tgtport:STATE:STARTSWITH("Docked") {
      local alignment is VXCL(tgtport:NODEPOSITION, tgtport:PORTFACING:FOREVECTOR):NORMALIZED * VANG(tgtport:NODEPOSITION, -tgtport:PORTFACING:FOREVECTOR) / 5.
      steer(tgtport:NODEPOSITION:NORMALIZED + alignment, MIN(tgtport:NODEPOSITION:MAG/10, 1), tgt).
    }

    CLEARVECDRAWS().
    wait until tgtport:STATE:STARTSWITH("Docked").

    print "Docked.".

  }

  function undock {
    parameter tgt.
    local agstate to AG10.
    print "Waiting for AG10.".
    wait until AG10 <> agstate.
    print "Undocking.".
    wait 3.
    RCS on.
    lock STEERING to LOOKDIRUP(tgt:POSITION, SHIP:FACING:TOPVECTOR).
    until tgt:POSITION:MAG > 10 {
      steer(-tgt:POSITION, 1, tgt).
    }
    print "Awaiting 100m distance.".
    until tgt:POSITION:MAG > 100 {
      steer(-tgt:POSITION, 5, tgt).
    }
    RCS off.
    print "Undock complete.".
  }

  function steer {
    parameter dir is V(0, 0, 0).
    parameter maxSpeed is 0.
    parameter tgt is TARGET.

    if maxSpeed > 0 and dir:MAG > maxSpeed {
      set dir:MAG to maxSpeed.
    }

    local tgtPro is -(tgt:VELOCITY:ORBIT - SHIP:VELOCITY:ORBIT).
    local str is dir - tgtPro.

    set SHIP:CONTROL:FORE to VDOT(SHIP:FACING:FOREVECTOR, str).
    set SHIP:CONTROL:TOP to VDOT(SHIP:FACING:TOPVECTOR, str).
    set SHIP:CONTROL:STARBOARD to VDOT(SHIP:FACING:STARVECTOR, str).

    wait 0.
  }

  export(lex(
    "rendezvous", rendezvous@,
    "dock", dock@,
    "undock", undock@
  )).
}
