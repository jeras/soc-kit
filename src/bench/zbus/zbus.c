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

//////////////////////////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////////////////////////

int zbus_reset ()
{
  int      c_i;
  zbus_d_i d_i;
  zbus_d_o d_o;
  int      c_o;
  unsigned int c_i_len, c_o_len;
  unsigned int d_i_len, d_o_len;
  unsigned int rst, stp;

  // read 'd_i'
  c_i_len = sizeof(PLI_INT32);
  c_i_len = read (f_i, &c_i, c_i_len);
  d_i_len = sizeof(zbus_d_i);
  d_i_len = read (f_i, &d_i, d_i_len);
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
    // write 'd_o'
    d_o_len = sizeof(zbus_d_o);
    d_o_len = write (f_o, &d_o, d_o_len);
    c_o_len = sizeof(PLI_INT32);
    c_o_len = write (f_o, &c_o, c_o_len);
    // read 'd_i'
    c_i_len = sizeof(PLI_INT32);
    c_i_len = read (f_i, &c_i, c_i_len);
    d_i_len = sizeof(zbus_d_i);
    d_i_len = read (f_i, &d_i, d_i_len);
    rst = c_i;
  }

  return 0;
}

//////////////////////////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////////////////////////

int zbus_rw (unsigned int wen, int adr, int dat)
{
  int      c_i;
  zbus_d_i d_i;
  zbus_d_o d_o;
  int      c_o;
  unsigned int c_i_len, c_o_len;
  unsigned int d_i_len, d_o_len;
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
    // write 'd_o'
    d_o_len = sizeof(zbus_d_o);
    d_o_len = write (f_o, &d_o, d_o_len);
    c_o_len = sizeof(PLI_INT32);
    c_o_len = write (f_o, &c_o, c_o_len);
    // read 'd_i'
    c_i_len = sizeof(PLI_INT32);
    c_i_len = read (f_i, &c_i, c_i_len);
    d_i_len = sizeof(zbus_d_i);
    d_i_len = read (f_i, &d_i, d_i_len);
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
      // write 'd_o'
      d_o_len = sizeof(zbus_d_o);
      d_o_len = write (f_o, &d_o, d_o_len);
      c_o_len = sizeof(PLI_INT32);
      c_o_len = write (f_o, &c_o, c_o_len);
      // read 'd_i'
      c_i_len = sizeof(PLI_INT32);
      c_i_len = read (f_i, &c_i, c_i_len);
      d_i_len = sizeof(zbus_d_i);
      d_i_len = read (f_i, &d_i, d_i_len);
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
  int      c_i;
  zbus_d_i d_i;
  zbus_d_o d_o;
  int      c_o;
  unsigned int c_i_len, c_o_len;
  unsigned int d_i_len, d_o_len;
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
    // write 'd_o'
    d_o_len = sizeof(zbus_d_o);
    d_o_len = write (f_o, &d_o, d_o_len);
    c_o_len = sizeof(PLI_INT32);
    c_o_len = write (f_o, &c_o, c_o_len);
    // read 'd_i'
    c_i_len = sizeof(PLI_INT32);
    c_i_len = read (f_i, &c_i, c_i_len);
    d_i_len = sizeof(zbus_d_i);
    d_i_len = read (f_i, &d_i, d_i_len);
    rst = c_i;
  }
}

//////////////////////////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////////////////////////

int zbus_stop ()
{
  int      c_i;
  zbus_d_i d_i;
  zbus_d_o d_o;
  int      c_o;
  unsigned int c_i_len, c_o_len;
  unsigned int d_i_len, d_o_len;
  unsigned int rst, stp;

  d_o.dat.aval = 0xffffffff;
  d_o.dat.bval = 0xffffffff;
  d_o.adr.aval = 0xffffffff;
  d_o.adr.bval = 0xffffffff;
  d_o.ctl.aval = 0x0000001f;
  d_o.ctl.bval = 0x0000001f;

  stp = 1;
  c_o = stp;

  // write 'd_o'
  d_o_len = sizeof(zbus_d_o);
  d_o_len = write (f_o, &d_o, d_o_len);
  c_o_len = sizeof(PLI_INT32);
  c_o_len = write (f_o, &c_o, c_o_len);

  return 0;
}



