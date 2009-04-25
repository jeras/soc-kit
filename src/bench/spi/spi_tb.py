#!/usr/bin/python

import sys
sys.path.append('../zbus/')
sys.path.append('src/bench/zbus/')
import zbus

#cpu = zbus.zbus_per (zo_file = "zo_file.txt", zi_file = "zi_file.txt")
cpu = zbus.zbus_per ()

cpu.write_32b (33, 177)
