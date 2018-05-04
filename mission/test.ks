{
  local launch is import("lib/launch").
  //local landing is import("lib/landing").
  local control is import("lib/control").

  control["staging"]().
  launch["verticalAscend"](100000).
  control["disableStaging"]().
  //control["vspeed"]({ return (100-ALT:RADAR) / 10. }).
  //launch["verticalAscend"](300).
  //landing["land"](0, 0.5, 0.6).
  wait until false.
}
