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

  export(lex(
    "getThrustVector", getThrustVector@
  )).
}
