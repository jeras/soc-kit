#include <vpi_user.h>

// TODO create an union for ctl
typedef struct {
  struct t_vpi_vecval dat, ctl;
} zbus_d_i;

typedef struct {
  uint32_t sel:4;
  uint32_t wen:1;
  uint32_t req:1;
  uint32_t ack:1;
} zbus_d_i_ctl;

// TODO create an union for ctl
typedef struct {
  struct t_vpi_vecval dat, adr, ctl;
} zbus_d_o;

typedef struct {
  uint32_t req:1;
  uint32_t ack:1;
} zbus_d_o_ctl;

int zbus_reset ();
int zbus_stop ();

//unsigned int ioread8(void *addr);
//unsigned int ioread16(void *addr);
uint32_t ioread32(void *addr);

//void iowrite8(u8 value, void *addr);
//void iowrite16(u16 value, void *addr);
void iowrite32(uint32_t value, void *addr);

//void ioread8_rep(void *addr, void *buf, unsigned long count);
//void ioread16_rep(void *addr, void *buf, unsigned long count);
//void ioread32_rep(void *addr, void *buf, unsigned long count);
//void iowrite8_rep(void *addr, const void *buf, unsigned long count);
//void iowrite16_rep(void *addr, const void *buf, unsigned long count);
//void iowrite32_rep(void *addr, const void *buf, unsigned long count);

