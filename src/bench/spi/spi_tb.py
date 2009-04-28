#!/usr/bin/python

import sys
sys.path.append('../zbus/')
sys.path.append('src/bench/zbus/')
sys.path.append('../interface/')
sys.path.append('src/bench/interface/')
import interface

cpu = interface.zbus_zpa (fno = "tmp/interface-o.fifo", fni = "tmp/interface-i.fifo")

# cpu.write_32b (33, 0x54)
# cpu.write_32b (34, 0x55)
# cpu.idle()
# cpu.write_32b (35, 0x56)
# cpu.idle()
# 
# for addr in range(4) :
#   data = cpu.read_32b (4*addr)
#   print data
# 
# cpu.idle()
# cpu.finish()
