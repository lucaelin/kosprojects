parameter node.
parameter ids is LEX().
  {
    local parent is node.
    local node is parent:addvbox().

    //attributes

    //childnodes
    {
      local parent is node.
      local node is parent:addlabel("mylabel").

      //attributes
      set node:style:font to "Roboto Monospace".
      set node:style:fontsize to 20.

      //childnodes
    }
    {
      local parent is node.
      local node is parent:addhbox().

      //attributes

      //childnodes
      {
        local parent is node.
        local node is parent:addlabel("mylabel2").

        //attributes
        ids:ADD("myelement", node).
        set node:style:font to "Roboto Monospace".
        set node:style:fontsize to 20.

        //childnodes
        set node:text to "<b>mylabel2 rich text</b>".
      }
      {
        local parent is node.
        local node is parent:addbutton().

        //attributes
        set node:onclick to { print "button pressed". }.

        //childnodes
        set node:text to "hi".
      }
    }
  }
