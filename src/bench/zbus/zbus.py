#!/usr/bin/python

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
    self.zo_ch = [open (zo_file, 'w') for zo_file in zo_files]
    print ("DEBUG: write file opened")
    # input ports
    self.zin = zin
    self.ziw = ziw
    print ("DEBUG: opening read file")
    self.zi_ch = [open (zi_file, 'r') for zi_file in zi_files]
    print ("DEBUG: read file opened")

  def zo_req (self, bus, ch = 0) :
    """
    """
    self.zo_ch[ch].write("req "+bus+"\n")

  def zi_rd (self, ch = 0) :
#    return 0
    return self.zi_ch[ch].readline()

  def zo_idl (self, ch = 0) :
    """
    """
    self.zo_ch[ch].write("idl\n")

  def zo_fin (self, ch = 0) :
    """
    """
    self.zo_ch[ch].write("fin\n")


class zbus_per (zbus) :
  """
  """

  def __init__ (self, zo_file = "zo_file.txt", zi_file = "zi_file.txt", AW = 32, DW = 32) :
    self.AW = AW
    self.DW = DW
    self.SW = DW/8
    zbus.__init__(self, zon = 1, zow = [1+self.SW+AW+DW], zo_files = [zo_file],
                        zin = 1, ziw = [             DW], zi_files = [zi_file])

  def write_32b (self, address, data, select = 0xf) :
    self.zo_req("1_%1x_%08x_%08x" % (select, address, data))

  def read_32b (self, address, select = 0xf) :
    self.zo_req("0_%1x_%08x_%s" % (select, address, "xxxxxxxx"))
    self.zo_idl()
    self.zo_idl()
    return self.zi_rd()
