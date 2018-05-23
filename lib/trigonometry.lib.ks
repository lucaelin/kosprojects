@lazyglobal off.
{
  local e is CONSTANT:E.

  function sinh {
    parameter x.
    set x to x * DEGTORAD.

    return (e^x - e^(-x)) / 2.
  }
  function cosh {
    parameter x.
    set x to x * DEGTORAD.

    return (e^x + e^(-x)) / 2.
  }
  function tanh {
    parameter x.

    return sinh(x) / cosh(x).
  }
  function coth {
    parameter x.

    return cosh(x) / sinh(x).
  }
  function sech {
    parameter x.

    // TODO: test
    return 1 / (cosh(x) * DEGTORAD).
  }
  function csch {
    parameter x.

    // TODO: test
    return 1 / (sinh(x) * DEGTORAD).
  }

  function arsinh {
    parameter x.
    return ln(x + SQRT(x^2 + 1)) * RADTODEG.
  }
  function arcosh {
    parameter x.
    return ln(x + SQRT(x^2 - 1)) * RADTODEG.
  }
  function artanh {
    parameter x.
    return 0.5 * ln((1 + x) / (1 - x)) * RADTODEG.
  }
  function arcoth {
    parameter x.
    return 0.5 * ln((x + 1) / (x - 1)) * RADTODEG.
  }
  function arsech {
    parameter x.
    return ln(1 / x + SQRT(1 / x^2 - 1)) * RADTODEG.
  }
  function arcsch {
    parameter x.
    return ln(1 / x + SQRT(1 / x^2 + 1)) * RADTODEG.
  }

  export(lex(
    "sinh", sinh@,
    "cosh", cosh@,
    "tanh", tanh@,
    "coth", coth@,
    "sech", sech@,
    "csch", csch@,
    "arsinh", arsinh@,
    "arcosh", arcosh@,
    "artanh", artanh@,
    "arcoth", arcoth@,
    "arsech", arsech@,
    "arcsch", arcsch@
  )).
}
