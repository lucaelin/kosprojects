@lazyglobal off.
{
  BRAKES on.
  on AG1 {
    wait 1.
    set SHIP:LOADDISTANCE:LANDED:UNLOAD to 30000.
    set SHIP:LOADDISTANCE:LANDED:PACK to 29000.
    timeout({
      print "Moving now.".
      BRAKES off.
      SAS on.
      lock WHEELTHROTTLE to 1.
      timeout({
        lock WHEELTHROTTLE to 0.02.
      }, 3).
    }, 60).
  }
  until false {
    print SHIP:VELOCITY:SURFACE:MAG at(0,1).
    wait 1.
  }.
}
