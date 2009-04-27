#!/usr/bin/python

import sys
sys.path.append('../zbus/')
sys.path.append('src/bench/zbus/')
import zbus

cpu = zbus.zbus_per (zo_file = "tmp/zo_file.txt", zi_file = "tmp/zi_file.txt")

cpu.write_32b (33, 0x54)
cpu.write_32b (34, 0x55)
cpu.idle()
cpu.write_32b (35, 0x56)
cpu.idle()

for addr in range(4) :
  data = cpu.read_32b (4*addr)
  print data

cpu.idle()
cpu.finish()
