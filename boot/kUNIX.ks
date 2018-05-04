{
  print "  _   _   _ _  _ _____  __ ".
  print " | |_| | | | \| |_ _\ \/ / ".
  print " | / / |_| | .` || | >  <  ".
  print " |_\_\\___/|_|\_|___/_/\_\ ".
  print "                           ".

  local currentImport is 0.
  local lookup is lex().

  function import {
    parameter path.

    set currentImport to path.
    // if lookup:HASKEY(currentImport) return lookup[currentImport]. // TODO: FIND OUT Y NOT WORKING
    // TODO: version management
    //if not EXISTS(path+".lib.ks") {
    if(HOMECONNECTION:ISCONNECTED) COPYPATH("0:/"+path+".lib.ks", "1:/"+path+".lib.ks").
    //}
    RUNPATH("1:/"+path+".lib.ks").
    return lookup[currentImport].
  }.

  function export {
    parameter lib.

    set lookup[currentImport] to lib.
  }.

  function await {
    parameter fn.

    local done is false.
    fn:CALL({set done to true.}).
    wait until done.
  }.

  function timeout {
    parameter cb.
    parameter t is 0.

    local timeAtCall is TIME:SECONDS + t.
    when TIME:SECONDS > timeAtCall then {
      cb:CALL().
    }
  }.

    global import is import@.
    global export is export@.
    global await is await@.
    global timeout is timeout@.
}
