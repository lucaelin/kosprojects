//*
//* A collection of nicetohave(tm) variables, locks and functions
//*

{
  global lock SURFACEPROGRADE to LOOKDIRUP(SHIP:VELOCITY:SURFACE, SHIP:FACING:TOPVECTOR).
  global lock SURFACERETROGRADE to LOOKDIRUP(-SHIP:VELOCITY:SURFACE, SHIP:FACING:TOPVECTOR).
  global lock ANTINORMAL to LOOKDIRUP(vcrs(ship:velocity:orbit,body:position), SHIP:FACING:TOPVECTOR).
  global lock NORMAL to LOOKDIRUP(-vcrs(ship:velocity:orbit,body:position), SHIP:FACING:TOPVECTOR).
  global lock RADIALOUT to LOOKDIRUP(vcrs(ship:velocity:orbit, vcrs(ship:velocity:orbit,body:position)), SHIP:FACING:TOPVECTOR).
  global lock RADIALIN to LOOKDIRUP(-vcrs(ship:velocity:orbit, vcrs(ship:velocity:orbit,body:position)), SHIP:FACING:TOPVECTOR).
  global lock UPTOP to LOOKDIRUP(SHIP:UP:VECTOR, SHIP:FACING:TOPVECTOR).

  global RADTODEG is 180/CONSTANT:PI.
  global DEGTORAD is CONSTANT:PI/180.

  global function MODMOD {
    parameter v.
    parameter n.

    return MOD(MOD(v, n) + n, n).
  }

  global function CLAMP {
    parameter a.
    parameter b.
    parameter v.

    return MAX(a, MIN(b, v)).
  }
  global function SIGN {
    parameter a.

    if a = 0 {
      return 0.
    }

    return a / ABS(a).
  }

  global function vecDrawBody {
    parameter tgt is SHIP:BODY.
    parameter vec is V(0,0,0).
    parameter color is WHITE.
    parameter lable is "".
    parameter scale is 1.
    parameter show is true.
    parameter width is 0.2.

    local draw is VECDRAW(tgt:POSITION,vec,color,lable,scale,show,width).
    set draw:STARTUPDATER to {
      return tgt:POSITION.
    }.
  }

  global function await {
    parameter fn.

    local done is false.
    fn:CALL({set done to true.}).
    wait until done.
  }

  global function timeout {
    parameter cb.
    parameter t is 0.

    local timeAtCall is TIME:SECONDS + t.
    when TIME:SECONDS > timeAtCall then {
      cb:CALL().
    }
  }

  global function recvMsg {
    wait until not CORE:MESSAGES:EMPTY.
    return CORE:MESSAGES:POP:CONTENT.
  }

  global function awaitInput {
    until not TERMINAL:INPUT:HASCHAR() {
      TERMINAL:INPUT:GETCHAR().
    }.
    print "Press any key (or send a message) to continute...".
    CORE:DOEVENT("Open Terminal").
    wait until TERMINAL:INPUT:HASCHAR() or not CORE:MESSAGES:EMPTY.
    if TERMINAL:INPUT:HASCHAR() { TERMINAL:INPUT:GETCHAR(). }
  }

  global function boot {
    parameter type is "missions".
    parameter name is SHIPNAME.
    parameter wait is true.

    print "Bootfile is being executed.".
    set CONFIG:IPU to MAX(CONFIG:IPU, 1000).

    if(HOMECONNECTION:ISCONNECTED) COPYPATH("0:/boot/kUNIX.ks", "1:/boot/kUNIX.ks").
    RUNPATH("/boot/kUNIX.ks").

    local initscript is type + "/" + name + ".ks".

    if wait {
      awaitInput().
    }

    CLEARSCREEN.
    if(HOMECONNECTION:ISCONNECTED) COPYPATH("0:/"+initscript, initscript).
    else print "Unable to update... using local script.".

    if wait {
      print "Running InitScript in".
      print "3".
      wait 1.
      print "2".
      wait 1.
      print "1".
      wait 1.
    }.

    SAS off.

    RUNPATH(initscript).

    print "InitScript finished.".
    until not TERMINAL:INPUT:HASCHAR() {
      TERMINAL:INPUT:GETCHAR().
    }.
    if not CONFIG:STAT {
      CORE:DOEVENT("Toggle Power").
    }
  }
}
