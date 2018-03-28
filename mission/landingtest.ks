{
  local launch is import("lib/launch").
  local landing is import("lib/landing").

  toggle GEAR.
  //launch["verticalAscend"](200).
  landing["land"](1.28, 0.3).
}
