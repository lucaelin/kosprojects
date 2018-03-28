{
  local landing is import("lib/landing").

  print BODY:NAME + " landing.".
  landing["land"](1.5).

  print "Jettison Skycrane.".

  local e is LIST().
  list ENGINES in e.
  set e to e[0].

  lock THROTTLE to 1.0.
  wait until e:THRUST > e:AVAILABLETHRUST * THROTTLE * 0.9.
  timeout({
    toggle AG4.
    BRAKES on.
  }).
}
