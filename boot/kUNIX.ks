//*
//* base functionality for the library import and export system
//*

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

    if lookup:HASKEY(path) return lookup[path].

    local previousImport is currentImport.
    set currentImport to path.

    if(HOMECONNECTION:ISCONNECTED) COPYPATH("0:/"+path+".lib.ks", "1:/"+path+".lib.ks").
    RUNPATH("1:/"+path+".lib.ks").

    set currentImport to previousImport.
    return lookup[path].
  }.

  function export {
    parameter lib.

    set lookup[currentImport] to lib.
  }.

  global import is import@.
  global export is export@.
}
