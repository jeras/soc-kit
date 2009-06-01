#include "zbus.h"
#include "spi.h"



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

  ioread16 (base+0x0);
  ioread16 (base+0x2);

  ioread8  (base+0x0);
  ioread8  (base+0x1);
  ioread8  (base+0x2);
  ioread8  (base+0x3);

  zbus_idle (4);

  iowrite32 (0x89abcdef, base+0x0);
  iowrite16 (    0x4567, base+0x0);
  iowrite16 (0x0123    , base+0x2);
  iowrite8  (      0xef, base+0x0);
  iowrite8  (    0xcd  , base+0x1);
  iowrite8  (  0xab    , base+0x2);
  iowrite8  (0x89      , base+0x3);

  zbus_idle (4);

  // write output fata
  iowrite32(0x89abcdef, base+0x4);
  
  iowrite32((0x01 << 24) + // set the clock divider
            (0x00 << 16) + // select only slave 0
            (3 << SPI_MODE_POS) +
            (0x00 <<  0),  // 
            base+0x0);

  zbus_idle (1);

  iowrite32((0x01 << 24) + // set the clock divider
            (0x01 << 16) + // select only slave 0
            SPI_OEN_MSK  +
            SPI_DIR_MSK  +
            (3 << SPI_MODE_POS) +
            (0x81 <<  0),  // 
            base+0x0);

//  iowrite32((0x00 << 24) + // set the clock divider
//            (0x00 << 16) + // select only slave 0
//            SPI_DIR_MSK  +
//            (2 << SPI_MODE_POS) +
//            (0x00 <<  0),  // 
//            base+0x0);

  zbus_idle (100);

  zbus_stop ();

  return 0;
}
