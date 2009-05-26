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

