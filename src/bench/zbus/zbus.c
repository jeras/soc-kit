#include <fcntl.h>
#include <unistd.h>

#include <stdio.h>
#include <string.h>

int main ()
{
  unsigned int i;
  int  zi,           zo;
  int  zi_status,    zo_status;
  char zi_str [128], zo_str [128];
  int  zi_len,       zo_len;
  char zi_inst [3],  zo_inst [3];
  int  zi_dat,       zo_dat;
  int                zo_adr;
  int                zo_sel;
  int                zo_wen;

  // open ZO stream
  zo = open ("tmp/zo_file.txt", O_WRONLY);
  if (zo<0)
    printf ("ERROR: Error opening ZO file.\n");
  else
    printf ("DEBUG: Success opening ZO file.\n");

  // open ZI stream
  zi = open ("tmp/zi_file.txt", O_RDONLY);
  if (zi<0)
    printf ("ERROR: Error opening ZI file.\n");
  else
    printf ("DEBUG: Success opening ZI file.\n");

  for (i=0; i<8; i++)
  {
    // read string
    zi_len = read (zi, zi_str, 128);
    zi_str[zi_len] = '\0';
    printf ("ZI: len = %3i, str = \"%s\"\n", zi_len, zi_str);
    // write string
    zo_len = 4;
    strcpy (zo_str, "idl\n");
    zo_str[zo_len] = '\0';
    printf ("ZO: len = %3i, str = \"%s\"\n", zo_len, zo_str);
    zo_len = write (zo, zo_str, zo_len);
    printf ("ZO: len = %3i, str = \"%s\"\n", zo_len, zo_str);
  }

  // write string
  zo_len = 4;
  strcpy (zo_str, "fin\n");
  zo_str[zo_len] = '\0';
  printf ("ZO: len = %3i, str = \"%s\"\n", zo_len, zo_str);
  zo_len = write (zo, zo_str, zo_len);
  printf ("ZO: len = %3i, str = \"%s\"\n", zo_len, zo_str);

  return 0;
}   
//    zi_status = fscanf (zi, "%s", zi_inst);
//    if (zi_status<0) printf ("ERROR: ZI scanf return status: %i", zi_status);
//    if (strcmp(zi_inst, "req"))
//      zi_status = fscanf (zi, " %s", zi_inst);

