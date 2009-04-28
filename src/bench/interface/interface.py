#!/usr/bin/python

import sys

class interface () :
  """
  """

  def __init__  (self, wo = 0, wi = 0, fno = "interface-o.fifo", fni = "interface-i.fifo") :
    """
    """
    # output ports
    self.wo = wo
    print ("DEBUG: Opening output signals (write) file: \"%s\"" % fno)
    self.fpo = open (fno, 'w')
    print ("DEBUG: write file opened")
    # input ports
    self.wi = wi
    print ("DEBUG: Opening input  signals (read)  file: \"%s\"." % fni)
    self.fpi = open (fni, 'r')
    print ("DEBUG: read  file opened")

  def rd (self) :
    ""
    i = self.fpi.readline()
    print ("I: %s" % i)
    return i

  def wr (self, o) :
    ""
    print ("O: %s" % o)
    self.fpo.write(o+"\n")
    self.fpo.flush()


class zbus_zpa (interface) :
  """
  outputs: zi_ack, zo_req, zo_wen, zo_sel[3:0], zo_adr[31:0], zo_dat[31:0]
  inputs:  zo_ack, zi_req,                                    zi_dat[31:0]
  """

  def __init__ (self, fno = "", fni = "", AW = 32, DW = 32) :
    self.AW = AW
    self.DW = DW
    self.SW = DW/8
    interface.__init__(self, wo = 1+self.SW+AW+DW, wi = DW, fno = fno, fni = fni)
    # bus initialization and dummy read
#    sys.stdin.read(1)
#    self.wr ("4xxxxxxxxxxxxxxx32\n")
#    self.fpo.flush()
#    sys.stdin.read(1)
#    self.wr ("4_x_xxxxxxxx_xxxxxxxx \n")
#    self.rd ()
    i = self.idle()
    sys.stdin.read(1)

  def write_32b (self, address, data, select = 0xf) :
    o = "%1x_%1x_%08x_%08x" % (4+2+1, select, address, data)
    while True :
      self.wr (o)
      i = self.rd ()
      zo_ack = (i[0] >> 1) & 1
      zi_req = (i[0] >> 0) & 1
      if zo_ack : return

  def read_32b (self, address, select = 0xf) :
    o = "%1x_%1x_%08x_%08x" % (4+2+1, select, address, "xxxxxxxx")
    while True :
      self.wr (o)
      i = self.rd ()
      zo_ack = (i[0] >> 1) & 1
      zi_req = (i[0] >> 0) & 1
      if zo_ack : break
    while not zi_req :
      i = self.idle()
      zo_ack = (i[0] >> 1) & 1
      zi_req = (i[0] >> 0) & 1
      if zi_req : return eval(i[1:8])

  def idle (self, n=1) :
    o = "%1x_%s_%s_%s" % (4+0+0, "x", "xxxxxxxx", "xxxxxxxx")
    for x in range(n) :
      self.wr (o)
      i = self.rd ()
    return i

 
# class zbus (interface) :
#   """
#   """
# 
#   def __init__  (self, zon = 1, zow = [32], zin = 1, ziw = [32],
#                  fnr = "zbus_vw_cr.txt", fnw = "zbus_vr_cw.txt") :
#     """
#     """
#     # output ports
#     self.zon = zon
#     self.zow = zow
#     print ("DEBUG: opening write file")
#     self.fpw = open (fnw, 'w')
#     print ("DEBUG: write file opened")
#     # input ports
#     self.zin = zin
#     self.ziw = ziw
#     print ("DEBUG: opening read file")
#     self.fpr = open (zi_file, 'r')
#     print ("DEBUG: read file opened")
# 
#   def zr (self, ) :
#     """
#     """
#     payload = self.zi[ch].readline() for ch in range(self.zin)]
#     for ch in range(self.zin) : print ("ZI[%d]: %s" % (ch, payload[ch]))
#     return payload
#     #return [0 for ch in range(self.zin)]
#     #return [self.zi[ch].readline() for ch in range(self.zin)]
# 
#   def zw (self, payload) :
#     """
#     """
#     for ch in range(self.zin) : print ("ZO[%d]: %s" % (ch, payload[ch]))
#     for ch in range(self.zon) : self.zo[ch].write(payload[ch])
# 
# 
# class zbus_per (zbus) :
#   """
#   """
# 
#   def __init__ (self, zo_file = "zo_file.txt", zi_file = "zi_file.txt", AW = 32, DW = 32) :
#     self.AW = AW
#     self.DW = DW
#     self.SW = DW/8
#     zbus.__init__(self, zon = 1, zow = [1+self.SW+AW+DW], zo_files = [zo_file],
#                         zin = 1, ziw = [             DW], zi_files = [zi_file])
#     # a dummy read
#     self.zr ()
# 
#   def write_32b (self, address, data, select = 0xf) :
#     self.zw (["req 1_%1x_%08x_%08x\n" % (select, address, data)])
#     self.zr ()
# 
#   def read_32b (self, address, select = 0xf) :
#     self.zw (["req 0_%1x_%08x_%s\n" % (select, address, "xxxxxxxx")])
#     return self.zr ()
# 
#   def idle (self) :
#     self.zw (["idl\n"])
#     self.zr ()
# 
#   def finish (self) :
#     self.zw (["fin\n"])
#     self.zr ()

 
