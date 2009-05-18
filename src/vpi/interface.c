#include  <vpi_user.h>
//#include  <stdlib.h>

#include <fcntl.h>
#include <unistd.h>

// FIFO file descriptors
int f_i, f_o;

//////////////////////////////////////////////////////////////////////////////
// interface initialization                                                 //
//////////////////////////////////////////////////////////////////////////////

static int interface_init_calltf(char*user_data)
{
  vpiHandle argh;
  struct t_vpi_value fno, fni;
 
  // Obtain a handle to the argument list
  vpiHandle systfref  = vpi_handle(vpiSysTfCall, NULL);
  vpiHandle args_iter = vpi_iterate(vpiArgument, systfref);

  // Grab the value of the first argument
  argh = vpi_scan(args_iter);
  fno.format = vpiStringVal;
  vpi_get_value(argh, &fno);
  f_o = open (fno.value.str, O_RDONLY);
  if (f_o<0)  printf ("VPI_ERROR: Error   opening O file: \"%s\"\n", fno.value.str);
  else        printf ("VPI_DEBUG: Success opening O file: \"%s\"\n", fno.value.str);

  // Grab the value of the first argument
  argh = vpi_scan(args_iter);
  fni.format = vpiStringVal;
  vpi_get_value(argh, &fni);
  f_i = open (fni.value.str, O_WRONLY);
  if (f_i<0)  printf ("VPI_ERROR: Error   opening O file: \"%s\"\n", fni.value.str);
  else        printf ("VPI_DEBUG: Success opening O file: \"%s\"\n", fni.value.str);
 
  // Cleanup and return
  vpi_free_object(args_iter);
  return 0;
}

static int interface_init_compiletf(char*user_data)
{
  return 0;
}

//////////////////////////////////////////////////////////////////////////////
// interface event                                                          //
//////////////////////////////////////////////////////////////////////////////

static int interface_event_calltf(char*user_data)
{
  vpiHandle argh;
  struct t_vpi_value d_i, d_o;
  unsigned int d_i_size, d_o_size;  // size of vector/structure
 
  // Obtain a handle to the argument list
  vpiHandle systfref  = vpi_handle(vpiSysTfCall, NULL);
  vpiHandle args_iter = vpi_iterate(vpiArgument, systfref);

  // grab argument d_i
  argh = vpi_scan(args_iter);
  d_i.format = vpiVectorVal;
  vpi_get_value(argh, &d_i);
  // comute the size of the d_i structure
  d_i_size = vpi_get(vpiSize, argh);
  d_i_size = (d_i_size-1)/(8*sizeof(PLI_INT32))+1;
  d_i_size =  d_i_size*sizeof(struct t_vpi_vecval);
  // send 'd_i'
  d_i_size = write (f_i, d_i.value.vector, d_i_size);
 
  // grab argument d_o
  argh = vpi_scan(args_iter);
  d_o.format = vpiVectorVal;
  vpi_get_value(argh, &d_o);
  // compute the size of the d_o structure
  d_o_size = vpi_get(vpiSize, argh);
  d_o_size = (d_o_size-1)/(8*sizeof(PLI_INT32))+1;
  d_o_size =  d_o_size*sizeof(struct t_vpi_vecval);
  // receive 'd_oi'
  d_o_size = read (f_o, d_o.value.vector, d_o_size);

  vpi_put_value(argh, &d_o, NULL, vpiNoDelay);

//  read (f_o, &cmd, 1);
//  if (cmd)
//  {
//    close(f_i);
//    close(f_o);
//    vpi_sim_control(vpiFinish, 0);
//  }

  // Cleanup
  vpi_free_object(args_iter);

  return 0;
}

static int interface_event_compiletf(char*user_data)
{
  return 0;
}

//////////////////////////////////////////////////////////////////////////////
// register VPI functions                                                   //
//////////////////////////////////////////////////////////////////////////////

void interface_init_register()
{
  s_vpi_systf_data tf_data;

  tf_data.type        = vpiSysTask;
  tf_data.sysfunctype = vpiSysTask;
  tf_data.tfname      = "$interface_init";
  tf_data.calltf      = interface_init_calltf;
  tf_data.compiletf   = interface_init_compiletf;
  tf_data.sizetf      = NULL;
  tf_data.user_data   = NULL;
  vpi_register_systf(&tf_data);
}

void interface_event_register()
{
  s_vpi_systf_data tf_data;

  tf_data.type        = vpiSysTask;
  tf_data.sysfunctype = vpiSysTask;
  tf_data.tfname      = "$interface_event";
  tf_data.calltf      = interface_event_calltf;
  tf_data.compiletf   = interface_event_compiletf;
  tf_data.sizetf      = NULL;
  tf_data.user_data   = NULL;
  vpi_register_systf(&tf_data);
}

void (*vlog_startup_routines[])() = {
  interface_init_register,
  interface_event_register,
  0
};
