#include <interface.h>

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

int interface_exchange (void *d__o, unsigned int d__o_len,
                        void *c__o, unsigned int c__o_len,
                        void *c__i, unsigned int c__i_len,
                        void *d__i, unsigned int d__i_len)
{
  int error = 0;
  // send    data to   Verilog VPI
  if (d__o_len)  error += d__o_len != write (f_o, d__o, d__o_len);
  if (c__o_len)  error += c__o_len != write (f_o, c__o, c__o_len);
  // receive data from Verilog VPI
  if (c__i_len)  error += c__i_len != read  (f_i, c__i, c__i_len);
  if (d__i_len)  error += d__i_len != read  (f_i, d__i, d__i_len);
  // return en error
  return (error);
}


