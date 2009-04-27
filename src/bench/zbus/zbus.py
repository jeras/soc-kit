#!/usr/bin/python

import os

class zbus () :
  """
  """

  def __init__  (self, zon = 1, zow = [32], zo_files = ["zo_file.txt"],
                       zin = 1, ziw = [32], zi_files = ["zi_file.txt"]) :
    """
    """
    # output ports
    self.zon = zon
    self.zow = zow
    print ("DEBUG: opening write file")
    self.zo = [open (zo_file, 'w') for zo_file in zo_files]
    #self.zo_ch = [os.fdopen(os.open(zo_file, os.O_NONBLOCK)) for zo_file in zo_files]
    print ("DEBUG: write file opened")
    # input ports
    self.zin = zin
    self.ziw = ziw
    print ("DEBUG: opening read file")
    self.zi = [open (zi_file, 'r') for zi_file in zi_files]
    #self.zi_ch = [os.fdopen(os.open(zi_file, os.O_RDONLY | os.O_NONBLOCK)) for zi_file in zi_files]
    print ("DEBUG: read file opened")

  def zr (self) :
    """
    """
    payload = [self.zi[ch].readline() for ch in range(self.zin)]
    for ch in range(self.zin) : print ("ZI[%d]: %s" % (ch, payload[ch]))
    return payload
    #return [0 for ch in range(self.zin)]
    #return [self.zi[ch].readline() for ch in range(self.zin)]

  def zw (self, payload) :
    """
    """
    for ch in range(self.zin) : print ("ZO[%d]: %s" % (ch, payload[ch]))
    for ch in range(self.zon) : self.zo[ch].write(payload[ch])

#  def zo_req (self, bus, ch = 0) :
#    self.zo[ch].write("req "+bus+"\n")
#    self.zo[ch].flush()
#
#  def zi_rd (self, ch = 0) :
##    wait
##    return 0
#    line = "idl"
##    while (line[0:3] == "idl") :
#    line = self.zi[ch].readline()
#    print line, type(line), len(line)
#    return line
#
#  def zo_idl (self, ch = 0) :
#    self.zo[ch].write("idl\n")
#    self.zo[ch].flush()
#
#  def zo_fin (self, ch = 0) :
#    self.zo[ch].write("fin\n")
#    self.zo[ch].flush()


class zbus_per (zbus) :
  """
  """

  def __init__ (self, zo_file = "zo_file.txt", zi_file = "zi_file.txt", AW = 32, DW = 32) :
    self.AW = AW
    self.DW = DW
    self.SW = DW/8
    zbus.__init__(self, zon = 1, zow = [1+self.SW+AW+DW], zo_files = [zo_file],
                        zin = 1, ziw = [             DW], zi_files = [zi_file])
    # a dummy read
    self.zr ()

  def write_32b (self, address, data, select = 0xf) :
    self.zw (["req 1_%1x_%08x_%08x\n" % (select, address, data)])
    self.zr ()

  def read_32b (self, address, select = 0xf) :
    self.zw (["req 0_%1x_%08x_%s\n" % (select, address, "xxxxxxxx")])
    return self.zr ()

  def idle (self) :
    self.zw (["idl\n"])
    self.zr ()

  def finish (self) :
    self.zw (["fin\n"])
    self.zr ()

 
