@lazyglobal off.
{
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
