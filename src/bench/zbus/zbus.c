#include "interface.h"
#include "zbus.h"

#include <vpi_user.h>

#include <fcntl.h>
#include <unistd.h>

#include <stdio.h>

//unsigned int ioread8(void *addr);
//unsigned int ioread16(void *addr);
uint32_t ioread32(void *addr)
{
  return zbus_rw(0, addr, 0);
}

//void iowrite8(u8 value, void *addr);
//void iowrite16(u16 value, void *addr);
void iowrite32(uint32_t value, void *addr)
{
  zbus_rw(1, addr, value);
}

int interface_exchange (void *d__o, unsigned int d__o_len,
                        void *c__o, unsigned int c__o_len,
                        void *c__i, unsigned int c__i_len,
                        void *d__i, unsigned int d__i_len)
{
  int error = 0;
  // send    data to   Verilog VPI
  if (d__o_len != write (f_o, d__o, d__o_len))  error++;
  if (c__o_len != write (f_o, c__o, c__o_len))  error++;
  // receive data from Verilog VPI
  if (c__i_len != read  (f_i, c__i, c__i_len))  error++;
  if (d__i_len != read  (f_i, d__i, d__i_len))  error++;
  // return en error
  return (error);
}

// shared global structures
int      c_i;
zbus_d_i d_i;
zbus_d_o d_o;
int      c_o;
// constant structure sizes
const unsigned int d_o_len = sizeof(zbus_d_o);
const unsigned int c_o_len = sizeof(PLI_INT32);
const unsigned int c_i_len = sizeof(PLI_INT32);
const unsigned int d_i_len = sizeof(zbus_d_i);

//////////////////////////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////////////////////////

int zbus_reset ()
{
  unsigned int rst, stp;

  interface_exchange (&d_o, 0, &c_o, 0, &c_i, c_i_len, &d_i, d_i_len);
  rst = c_i;

  d_o.dat.aval = 0xffffffff;
  d_o.dat.bval = 0xffffffff;
  d_o.adr.aval = 0xffffffff;
  d_o.adr.bval = 0xfffffff0;
  d_o.ctl.aval = 0x0000001f;
  d_o.ctl.bval = 0x0000001f;

  stp = 0;
  c_o = stp;

  while (rst)
  {
    interface_exchange (&d_o, d_o_len, &c_o, c_o_len, &c_i, c_i_len, &d_i, d_i_len);
    rst = c_i;
  }

  return 0;
}

//////////////////////////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////////////////////////

int zbus_rw (unsigned int wen, int adr, int dat)
{
  unsigned int rst, stp;
  unsigned int ack, req;

  d_o.dat.aval = dat;
  d_o.dat.bval = 0x00000000;
  d_o.adr.aval = adr;
  d_o.adr.bval = 0x00000000;
  d_o.ctl.aval = 0x0000006f + (wen << 4);
  d_o.ctl.bval = 0x00000000;

  stp = 0;
  c_o = stp;

  ack = 0;

  while (!ack)
  {
    interface_exchange (&d_o, d_o_len, &c_o, c_o_len, &c_i, c_i_len, &d_i, d_i_len);
    rst = c_i;
    ack = d_i.ctl.aval & 0x2;
  }

  if (!wen)
  {
    req = d_i.ctl.aval & 0x1;
  
    d_o.dat.aval = 0xffffffff;
    d_o.dat.bval = 0xffffffff;
    d_o.adr.aval = 0xffffffff;
    d_o.adr.bval = 0xffffffff;
    d_o.ctl.aval = 0x0000001f;
    d_o.ctl.bval = 0x0000001f;
  
    while (!req) {
      interface_exchange (&d_o, d_o_len, &c_o, c_o_len, &c_i, c_i_len, &d_i, d_i_len);
      rst = c_i;
      req = d_i.ctl.aval & 0x1;
    }
  }

  dat = d_i.dat.aval;

  return dat;
}

//////////////////////////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////////////////////////

void zbus_idle (unsigned int cycles)
{
  unsigned int rst, stp;
  unsigned int n;

  d_o.dat.aval = 0xffffffff;
  d_o.dat.bval = 0xffffffff;
  d_o.adr.aval = 0xffffffff;
  d_o.adr.bval = 0xffffffff;
  d_o.ctl.aval = 0x0000001f;
  d_o.ctl.bval = 0x0000001f;

  stp = 0;
  c_o = stp;

  for (n = 0; n < cycles; n++)
  {
    interface_exchange (&d_o, d_o_len, &c_o, c_o_len, &c_i, c_i_len, &d_i, d_i_len);
    rst = c_i;
  }
}

//////////////////////////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////////////////////////

int zbus_stop ()
{
  unsigned int rst, stp;

  d_o.dat.aval = 0xffffffff;
  d_o.dat.bval = 0xffffffff;
  d_o.adr.aval = 0xffffffff;
  d_o.adr.bval = 0xffffffff;
  d_o.ctl.aval = 0x0000001f;
  d_o.ctl.bval = 0x0000001f;

  stp = 1;
  c_o = stp;
  interface_exchange (&d_o, d_o_len, &c_o, c_o_len, &c_i, 0, &d_i, 0);

  return 0;
}



