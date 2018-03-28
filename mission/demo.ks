{
  set SHIPNAME to SHIPNAME:SPLIT(" @ ")[0].

  lock STEERING to PROGRADE.

  wait 10.
  until STAGE:NUMBER = 0 {
    wait until STAGE:READY.
    stage.
    wait 1.
  }
}
