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
  unsigned int rst:1;
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

//int interface_event (

int main ()
{
  char *fno = "tmp/interface-o.fifo";
  char *fni = "tmp/interface-i.fifo";
  unsigned int cnt, cycles = 32;
  char rst;
//  char d_i [5],  d_o [9];
  zbus_d_i d_i;
  zbus_d_o d_o;
  int  d_i_len,  d_o_len, rst_len;

  int  zi_dat,   zo_dat;
  int            zo_adr;
  int            zo_sel;
  int            zo_wen;

  interface_init (fno, fni);

  for (cnt=0; cnt<cycles; cnt++)
  {
    // read 'd_i'
    d_i_len = sizeof(zbus_d_i);
    d_i_len = read (f_i, &d_i, d_i_len);
    rst = (d_i.ctl.aval >> 2) & 1;
    printf ("FW_DEBUG: rst = %i\n", rst);
    // write 'd_o'
    d_o.dat.aval = rst ? 0xa5 : 0x5a;
    d_o.adr.aval = 0x1234567;
    d_o_len = sizeof(zbus_d_o);
    d_o_len = write (f_o, &d_o, d_o_len);
    
//    if (cnt<cycles) rst = 0;
//    else            rst = 1;
//    write (f_o, &rst, 1);
  }

  return 0;
}
