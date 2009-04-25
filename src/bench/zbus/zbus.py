#!/usr/bin/python

class zbus () :
  """
  """

  def __init__  (self, zon = 1, zow = 32, zo_files = "zo_file.txt",
                       zin = 1, ziw = 32, zi_files = "zi_file.txt") :
    """
    """
    # output ports
    self.zon = zon
    self.zow = zow
    self.zo_ch = open (zo_files, 'w')
    # input ports
    self.zin = zin
    self.ziw = ziw
    self.zi_ch = open (zi_files, 'r')

  def zo_wr (self, bus, ch = 0) :
    """
    """
    self.zo_ch.write(bus+"\n")

  def zo_iv (self) :
    """
    """
    self.zo_ch.write("idle\n")

  def zi_rd (self, ch = 0) :
    return self.zi_ch.read()


class zbus_per (zbus) :
  """
  """

  def __init__ (self, zo_file = "zo_file.txt", zi_file = "zi_file.txt") :
    zbus.__init__(self, zo_files = zo_file, zi_files = zi_file)

  def write_32b (self, address, data, select = 0xf) :
    self.zo_wr("1_%01x_%032x_%032x" % (select, address, data))

  def read_32b (self, address, select = 0xf) :
    self.zo_wr("0_%01x_%032x_%s" % (select, address, "xxxxxxxx"))
    self.zo_iv()
    self.zo_iv()
    return self.zi_rd()
