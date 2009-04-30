#include <fcntl.h>
#include <unistd.h>

#include <stdio.h>
#include <string.h>

int main ()
{
  char *fni = "tmp/interface-i.fifo";
  char *fno = "tmp/interface-o.fifo";
  unsigned int cnt;
  int  i,           o;
  int  i_status,    o_status;
  char i_str [128], o_str [128];
  int  i_len,       o_len;
  char i_inst [3],  o_inst [3];
  int  i_dat,       o_dat;
  int               o_adr;
  int               o_sel;
  int               o_wen;

  // open ZO stream
  o = open (fno, O_WRONLY);
  if (o<0)  printf ("ERROR: Error   opening O file: \"%s\"\n", fno);
  else      printf ("DEBUG: Success opening O file: \"%s\"\n", fno);

  // open ZI stream
  i = open (fni, O_RDONLY);
  if (i<0)  printf ("ERROR: Error   opening I file: \"%s\"\n", fni);
  else      printf ("DEBUG: Success opening I file: \"%s\"\n", fni);

  for (cnt=0; cnt<8; cnt++)
  {
    printf ("LOOP: %i\n", cnt);
    // write string
    o_len = 22;
    strcpy (o_str, "0_x_xxxxxxxx_xxxxxxxx \n");
    o_str[o_len] = '\0';
    o_len = write (o, o_str, o_len);
    printf ("O: len = %3i, str = \"%s\"\n", o_len, o_str);
    // read string
    i_len = read (i, i_str, 128);
    i_str[i_len] = '\0';
    printf ("I: len = %3i, str = \"%s\"\n", i_len, i_str);
  }

  // write string
  o_len = 22;
  strcpy (o_str, "0_x_xxxxxxxx_xxxxxxxx\n");
  o_str[o_len] = '\0';
  o_len = write (o, o_str, o_len);
  printf ("O: len = %3i, str = \"%s\"\n", o_len, o_str);

  return 0;
}   
//    i_status = fscanf (i, "%s", i_inst);
//    if (i_status<0) printf ("ERROR: ZI scanf return status: %i", i_status);
//    if (strcmp(i_inst, "req"))
//      i_status = fscanf (i, " %s", i_inst);

