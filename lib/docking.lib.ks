@lazyglobal off.
{
  function tgtPrograde {
    return LOOKDIRUP(-(TARGET:VELOCITY:ORBIT - SHIP:VELOCITY:ORBIT), SHIP:FACING:TOPVECTOR).
  }
  function tgtRetrograde {
    return LOOKDIRUP(TARGET:VELOCITY:ORBIT - SHIP:VELOCITY:ORBIT, SHIP:FACING:TOPVECTOR).
  }
  function rendezvous {
    parameter tgt is TARGET.

    lock STEERING to tgtRetrograde().

    print "Awaiting close approach.".

    wait until tgt:POSITION:MAG < 5000.

    print "Killing relative velocity.".

    lock THROTTLE to 1.
    wait until (tgt:VELOCITY:ORBIT - SHIP:VELOCITY:ORBIT):MAG < (SHIP:AVAILABLETHRUST / SHIP:MASS).
    lock THROTTLE to 0.

    RCS on.
    set SHIP:CONTROL:FORE to 1.
    wait until (tgt:VELOCITY:ORBIT - SHIP:VELOCITY:ORBIT):MAG < 1.
    set SHIP:CONTROL:FORE to 0.
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
    local tgtports is TARGET:DOCKINGPORTS:ITERATOR.
    local tgtport is TARGET:DOCKINGPORTS[0].
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

    CLEARVECDRAWS().
    VECDRAW(V(0,0,0), dir, white, "dir", 1, true, .2).
    VECDRAW(V(0,0,0), str, red, "steer", 1, true, .2).
    VECDRAW(V(0,0,0), tgtPro, red, "pro", 1, true, .2).
    VECDRAW(V(0,0,0), SHIP:FACING:FOREVECTOR, RGBA(1,0,0,0.2), "fore", 1, true, 0.05).
    VECDRAW(V(0,0,0), SHIP:FACING:STARVECTOR, RGBA(0,1,0,0.2), "star", 1, true, 0.05).
    VECDRAW(V(0,0,0), SHIP:FACING:TOPVECTOR, RGBA(0,0,1,0.2), "top", 1, true, 0.05).

    wait 0.
  }

  export(lex(
    "rendezvous", rendezvous@,
    "dock", dock@
  )).
}
