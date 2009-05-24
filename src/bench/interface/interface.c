#include <vpi_user.h>

#include <fcntl.h>
#include <unistd.h>

#include <stdio.h>
#include <string.h>

// ifnterface FIFO file descriptors
int f_o, f_i;

// TODO create an union for ctl
typedef struct {
  struct t_vpi_vecval dat, ctl;
} zbus_d_i;

typedef struct {
  unsigned int sel:4;
  unsigned int wen:1;
  unsigned int req:1;
  unsigned int ack:1;
} zbus_d_i_ctl;

// TODO create an union for ctl
typedef struct {
  struct t_vpi_vecval dat, adr, ctl;
} zbus_d_o;

typedef struct {
  unsigned int req:1;
  unsigned int ack:1;
} zbus_d_o_ctl;


int interface_init (char *fno, char *fni)
{
  // open ZO stream
  f_o = open (fno, O_WRONLY);
  if (f_o<0)  printf ("CPU_ERROR: Error   opening d_o file: \"%s\"\n", fno);
  else        printf ("CPU_DEBUG: Success opening d_o file: \"%s\"\n", fno);

  // open ZI stream
  f_i = open (fni, O_RDONLY);
  if (f_i<0)  printf ("CPU_ERROR: Error   opening d_i file: \"%s\"\n", fni);
  else        printf ("CPU_DEBUG: Success opening d_i file: \"%s\"\n", fni);

  return ((f_o<0) || (f_i<0));
}

//////////////////////////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////////////////////////

int interface_reset ()
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

int interface_rw (unsigned int wen, int adr, int dat)
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

int interface_stop ()
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


//////////////////////////////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////////////////////////////

int main ()
{
  char *fno = "tmp/interface-o.fifo";
  char *fni = "tmp/interface-i.fifo";
  unsigned int cnt, cycles = 16;
  char rst;
//  char d_i [5],  d_o [9];
  zbus_d_i d_i;
  zbus_d_o d_o;
  int c_i, c_o;
  unsigned int c_i_len, c_o_len;
  int  d_i_len,  d_o_len, rst_len;

  int  zi_dat,   zo_dat;
  int            zo_adr;
  int            zo_sel;
  int            zo_wen;

  interface_init (fno, fni);

#if 1

  interface_reset ();
  interface_rw    (0, 0x76543210, 0x32323232);
  interface_rw    (0, 0x76543214, 0x14141414);
  interface_rw    (1, 0x01234567, 0xa5a55a5a);
  interface_rw    (1, 0x89abcdef, 0x5a5aa5a5);
  interface_stop  ();

#else

  for (cnt=0; cnt<cycles; cnt++)
  {
    // read 'd_i'
    c_i_len = sizeof(PLI_INT32);
    c_i_len = read (f_i, &c_i, c_i_len);
    rst = c_i;
    d_i_len = sizeof(zbus_d_i);
    d_i_len = read (f_i, &d_i, d_i_len);
    printf ("FW_DEBUG: rst = %i\n", rst);
    // write 'd_o'
    d_o.dat.aval = rst ? 0xa5 : 0x5a;
    d_o.dat.bval = 0x00000000;
    d_o.adr.aval = 0x01234567;
    d_o.adr.bval = 0x00000000;
    d_o_len = sizeof(zbus_d_o);
    d_o_len = write (f_o, &d_o, d_o_len);
    if (cnt<7) c_o = 0;
    else            c_o = 1;
    write (f_o, &c_o, sizeof(PLI_INT32));
  }

#endif

  return 0;
}
