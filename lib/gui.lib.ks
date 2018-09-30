@lazyglobal off.
{
  local gui is GUI(400).
  gui:ADDLABEL("<size=18><b>KOS Monitor " + core:TAG + "</b></size>").
  set gui:X to -100.
  set gui:Y to 100.
  gui:SHOW().

  local guiEnabled is true.

  local contextTracking is LEX().
  on FLOOR(TIME:SECONDS * 5) {
    for callbacks in contextTracking:VALUES {
      for cb in callbacks {
        cb().
      }
    }
    PRESERVE.
  }

  function createContext {
    parameter name.

    local header is gui:ADDLABEL("<b><color=white>"+name:TOUPPER+"</color></b>").
    local vbox is gui:ADDVBOX.
    set vbox:STYLE:PADDING:H to 5.
    local labels is LEX().
    local callbacks is LIST().
    until not contextTracking:HASKEY(name) {
      set name to name + "-2".
    }
    contextTracking:ADD(name, callbacks).

    local vectors is LEX().

    return LEX(
      "log",{
        parameter key.
        parameter value.
        parameter unit is "".

        guiVal(key, value, unit, vbox, labels).
      },
      "track",{
        parameter key.
        parameter fn.
        parameter unit is "".

        guiVal(key, fn:CALL(), unit, vbox, labels).
        callbacks:ADD({
            guiVal(key, fn:CALL(), unit, vbox, labels).
        }).
      },
      "vec",{
        parameter name.
        parameter vec.
        parameter color is white.
        parameter start is V(0,0,0).

        guiVec(vectors, name, vec, color, start).
        guiVal("Vector "+name, vec:MAG, "m", vbox, labels).
      },
      "button",{
        parameter name.
        parameter cb.

        local button is vbox:ADDBUTTON(name).
        set button:ONCLICK to cb.
      },
      "remove",{
        parameter t is 5.

        print "about to remove "+ name.
        contextTracking:REMOVE(name).
        //timeout({ // not working while #2272 is open
          header:DISPOSE().
          vbox:DISPOSE().


          for v in vectors:VALUES {
            set v:SHOW to false.
          }
        //}, t).
      }
    ).
  }

  function guiVec {
    parameter vectors.
    parameter name.
    parameter vec.
    parameter color is white.
    parameter start is V(0,0,0).

    if vectors:HASKEY(name) {
      set vectors[name]:VEC to vec.
      set vectors[name]:START to start.
      return vectors[name].
    }
    set vectors[name] to VECDRAW(start, vec, color, name, 1, true, 0.2).
  }

  function guiVal {
    parameter key.
    parameter value.
    parameter unit.
    parameter context is GUI.
    parameter labels is LEX().

    if not guiEnabled return.

    set unit to " " + unit.

    if value:TYPENAME = "Scalar" {
      set value to (round(value * 100000) / 100000):TOSTRING + ".".
      local spl is value:SPLIT(".").
      set spl[1] to spl[1]:PADRIGHT(6).
      set value to spl[0]+"."+spl[1].
      value:REPLACE(" ", "0").
    }

    if(labels:HASKEY(key)) {
      set labels[key]:TEXT to "" + value + unit.
      return labels[key].
    }
    local hlayout is context:ADDHLAYOUT().
    set hlayout:STYLE:PADDING:V to 0.
    local keylabel is hlayout:ADDLABEL("<color=white>"+key+"</color>").
    set keylabel:STYLE:PADDING:V to 0.
    set keylabel:STYLE:FONT to "monospace".
    local label is hlayout:ADDLABEL(""+value).
    set label:STYLE:HSTRETCH to true.
    set label:STYLE:ALIGN to "RIGHT".
    set label:STYLE:PADDING:V to 0.
    set label:STYLE:FONT to "monospace".
    labels:ADD(key, label).

    return label.
  }

  function formatKeyValue {
    parameter key.
    parameter value.

    return "<color=white>"+key+"</color>: <color=yellow>"+value+"</color>".
  }

  function disableGUI {
    parameter val is true.

    set guiEnabled to val.
    if val {
      gui:HIDE.
    } else {
      gui:SHOW.
    }
  }

  function show {
    parameter text is "".

    HUDTEXT(
      text,
      10,
      2,
      15,
      white,
      false
    ).
  }
  function warn {
    parameter text is "".

    HUDTEXT(
      text,
      10,
      2,
      25,
      yellow,
      false
    ).
  }
  function error {
    parameter reason is "".

    HUDTEXT(
      reason,
      10,
      2,
      25,
      red,
      true
    ).
  }
  function fail {
    parameter reason is "".

    HUDTEXT(
      reason,
      10,
      2,
      25,
      magenta,
      true
    ).
    return 1/0. // real error below
  }
  function confirm {
    parameter msg is "".

    local done is false.
    local ctx is createContext("Confirm").
    ctx["button"](msg, { set done to true. }).
    wait until done.
    ctx["remove"]().
  }

  export(lex(
    "show", show@,
    "warn", warn@,
    "error", error@,
    "fail", fail@,
    "confirm", confirm@,
    "createContext", createContext@,
    "disableGUI", disableGUI@
  )).
}
