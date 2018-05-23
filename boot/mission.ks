//*
//* bootfile for payloads found in /mission
//* the payload with an attached launcher should have the following namescheme:
//* payloadname @ lauchername
//* this file reads the payloadname to run the corresponding file
//*

wait until SHIP:UNPACKED and SHIP:LOADED.
if(HOMECONNECTION:ISCONNECTED) COPYPATH("0:/boot/coreboot.ks", "1:/boot/coreboot.ks").
run "boot/coreboot.ks".
wait 1.
boot("mission", SHIPNAME:SPLIT(" @ ")[0]).
