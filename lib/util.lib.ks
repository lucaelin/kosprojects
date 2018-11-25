@lazyglobal off.
{
  //*
  //* get a vector pointing in the direction of thrust with its magitude being the amount of thrust available
  //*
  function getThrustVector {
    local elist is LIST().
    list ENGINES in elist.
    local thrustVec is V(0,0,0).

    for e in elist {
      set thrustVec to thrustVEC + e:FACING:FOREVECTOR * e:AVAILABLETHRUST.
    }
    return thrustVec.
  }

  function awaitInput {

  }

  function warpTill {
    parameter fn.
    parameter maxx is 10000.
    
    wait 0.
    local x is 1.
    until (x > maxx) or fn() {
      set KUNIVERSE:TIMEWARP:RATE to x.
      set x to x*10.
      wait 1.
    }
    wait until fn().
    KUNIVERSE:TIMEWARP:CANCELWARP().
    wait 0.
    wait until KUNIVERSE:TIMEWARP:ISSETTLED.
    wait 1.
  }

  export(lex(
    "getThrustVector", getThrustVector@,
    "awaitInput", awaitInput@,
    "warpTill", warpTill@
  )).
}
