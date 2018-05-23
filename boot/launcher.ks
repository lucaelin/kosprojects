//*
//* bootfile for launchvehicles found in /launcher
//* the ship with an attached payload should have the following namescheme:
//* payloadname @ lauchername
//* this file reads the launchername to run the corresponding file
//*

wait until SHIP:UNPACKED and SHIP:LOADED.
if(HOMECONNECTION:ISCONNECTED) COPYPATH("0:/boot/coreboot.ks", "1:/boot/coreboot.ks").
run "boot/coreboot.ks".
wait 1.
boot("launcher", SHIPNAME:SPLIT(" @ ")[1]).
