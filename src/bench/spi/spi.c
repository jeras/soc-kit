#include "zbus.h"

int main ()
{
  char *fno = "tmp/interface-o.fifo";
  char *fni = "tmp/interface-i.fifo";

  //uintptr_t *base;
  void *base;
  base = 0;

  interface_init (fno, fni);
  zbus_reset ();

  ioread32 (base+0x0);
  ioread32 (base+0x4);
  ioread32 (base+0x8);
  ioread32 (base+0xc);
  iowrite32(0x01234567, base+0x0);
  iowrite32(0x89abcdef, base+0x4);
  iowrite32(0xa5a5a5a5, base+0x8);
  iowrite32(0x5a5a5a5a, base+0xc);

  zbus_stop ();

  return 0;
}
