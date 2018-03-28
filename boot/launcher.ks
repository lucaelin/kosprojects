COPYPATH("0:/boot/coreboot.ks", "1:/boot/coreboot.ks").
run "boot/coreboot.ks".
wait 1.
boot("launcher", SHIPNAME:SPLIT(" @ ")[1]).
