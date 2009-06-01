#include "interface.h"
#include "zbus.h"

#include <vpi_user.h>

#include <fcntl.h>
#include <unistd.h>

#include <stdio.h>

uint8_t  ioread8 (void *addr)
{
  int shift = (uint32_t) addr & 0x3;
  return (zbus_rw(0, addr, 0x1 << shift, 0) >> (8*shift));
}

uint16_t ioread16 (void *addr)
{
  int shift = (uint32_t) addr & 0x3;
  return (zbus_rw(0, addr, 0x3 << shift, 0) >> (8*shift));
}

uint32_t ioread32 (void *addr)
{
  return zbus_rw(0, addr, 0xf, 0);
}

void iowrite8  (uint8_t  value, void *addr)
{
  int shift = (uint32_t) addr & 0x3;
  zbus_rw(1, addr, 0x1 << shift, value << (8*shift));
}

void iowrite16 (uint16_t value, void *addr)
{
  int shift = (uint32_t) addr & 0x3;
  zbus_rw(1, addr, 0x3 << shift, value << (8*shift));
}

void iowrite32 (uint32_t value, void *addr)
{
  zbus_rw(1, addr, 0xf, value);
}

//////////////////////////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////////////////////////

int zbus_exchange (int send_en, int receive_en)
{
  if (
    interface_exchange (
      &cd_io.d_o, send_en    ? sizeof(zbus_d_o)  : 0,
      &cd_io.c_o, send_en    ? sizeof(PLI_INT32) : 0,
      &cd_io.c_i, receive_en ? sizeof(PLI_INT32) : 0,
      &cd_io.d_i, receive_en ? sizeof(zbus_d_i)  : 0
    )
  )
    printf ("ZBUS EXCHANGE ERROR");
}

//////////////////////////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////////////////////////

int zbus_reset ()
{
  unsigned int rst, stp;

  zbus_exchange (0, 1);
  rst = cd_io.c_i;

  cd_io.d_o.dat.aval = 0xffffffff;
  cd_io.d_o.dat.bval = 0xffffffff;
  cd_io.d_o.adr.aval = 0xffffffff;
  cd_io.d_o.adr.bval = 0xfffffff0;
  cd_io.d_o.ctl.aval = 0x0000001f;
  cd_io.d_o.ctl.bval = 0x0000001f;

  stp = 0;
  cd_io.c_o = stp;

  while (rst)
  {
    zbus_exchange (1, 1);
    rst = cd_io.c_i;
  }

  return 0;
}

//////////////////////////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////////////////////////

int zbus_rw (unsigned int wen, int adr, int sel, int dat)
{
  unsigned int rst, stp;
  unsigned int ack, req;

  cd_io.d_o.dat.aval = dat;
  cd_io.d_o.dat.bval = 0x00000000;
  cd_io.d_o.adr.aval = adr;
  cd_io.d_o.adr.bval = 0x00000000;
  cd_io.d_o.ctl.aval = 0x00000060 + ((wen & 0x1) << 4) + (sel & 0xf);
  cd_io.d_o.ctl.bval = 0x00000000;

  stp = 0;
  cd_io.c_o = stp;

  ack = 0;

  while (!ack)
  {
    zbus_exchange (1, 1);
    rst = cd_io.c_i;
    ack = cd_io.d_i.ctl.aval & 0x2;
  }

  if (!wen)
  {
    req = cd_io.d_i.ctl.aval & 0x1;
  
    cd_io.d_o.dat.aval = 0xffffffff;
    cd_io.d_o.dat.bval = 0xffffffff;
    cd_io.d_o.adr.aval = 0xffffffff;
    cd_io.d_o.adr.bval = 0xffffffff;
    cd_io.d_o.ctl.aval = 0x0000001f;
    cd_io.d_o.ctl.bval = 0x0000001f;
  
    while (!req) {
      zbus_exchange (1, 1);
      rst = cd_io.c_i;
      req = cd_io.d_i.ctl.aval & 0x1;
    }
  }

  dat = cd_io.d_i.dat.aval;

  return dat;
}

//////////////////////////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////////////////////////

int zbus_idle (unsigned int cycles)
{
  unsigned int rst, stp;
  unsigned int n;

  cd_io.d_o.dat.aval = 0xffffffff;
  cd_io.d_o.dat.bval = 0xffffffff;
  cd_io.d_o.adr.aval = 0xffffffff;
  cd_io.d_o.adr.bval = 0xffffffff;
  cd_io.d_o.ctl.aval = 0x0000001f;
  cd_io.d_o.ctl.bval = 0x0000001f;

  stp = 0;
  cd_io.c_o = stp;

  for (n = 0; n < cycles; n++)
  {
    zbus_exchange (1, 1);
    rst = cd_io.c_i;
  }

  return 0;
}

//////////////////////////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////////////////////////

int zbus_stop ()
{
  unsigned int rst, stp;

  cd_io.d_o.dat.aval = 0xffffffff;
  cd_io.d_o.dat.bval = 0xffffffff;
  cd_io.d_o.adr.aval = 0xffffffff;
  cd_io.d_o.adr.bval = 0xffffffff;
  cd_io.d_o.ctl.aval = 0x0000001f;
  cd_io.d_o.ctl.bval = 0x0000001f;

  stp = 1;
  cd_io.c_o = stp;
  zbus_exchange (1, 0);

  return 0;
}



