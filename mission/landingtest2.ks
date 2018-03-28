{
  local launch is import("lib/launch").
  local landing is import("lib/landing").

  toggle GEAR.
  launch["verticalAscend"](500).
  landing["land"](7, 0.8).
}
