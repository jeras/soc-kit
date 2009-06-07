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

// shared global structures
typedef struct {
  int      c_i;
  zbus_d_i d_i;
  zbus_d_o d_o;
  int      c_o;
} zbus_cd_io;

zbus_cd_io cd_io;

int zbus_exchange (int, int);

int zbus_reset ();
int zbus_rw (unsigned int, int, int, int);
int zbus_idle (unsigned int);
int zbus_stop ();

uint8_t  ioread8  (void *);
uint16_t ioread16 (void *);
uint32_t ioread32 (void *);

void iowrite8  (uint8_t,  void *);
void iowrite16 (uint16_t, void *);
void iowrite32 (uint32_t, void *);

void ioread8_rep  (void *addr,       void *buf, unsigned long count);
void ioread16_rep (void *addr,       void *buf, unsigned long count);
void ioread32_rep (void *addr,       void *buf, unsigned long count);

void iowrite8_rep (void *addr, const void *buf, unsigned long count);
void iowrite16_rep(void *addr, const void *buf, unsigned long count);
void iowrite32_rep(void *addr, const void *buf, unsigned long count);

