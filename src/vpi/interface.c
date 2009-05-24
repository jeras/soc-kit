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

//////////////////////////////////////////////////////////////////////////////
// interface event                                                          //
//////////////////////////////////////////////////////////////////////////////

static int interface_event_calltf(char*user_data)
{
  vpiHandle argh;
  struct t_vpi_value c_i, d_i, d_o, c_o;
  unsigned int c_i_size, d_i_size, d_o_size, c_o_size;  // size of vector/structure
 
  // Obtain a handle to the argument list
  vpiHandle systfref  = vpi_handle(vpiSysTfCall, NULL);
  vpiHandle args_iter = vpi_iterate(vpiArgument, systfref);

  // grab argument c_i
  argh = vpi_scan(args_iter);
  c_i.format = vpiIntVal;
  vpi_get_value(argh, &c_i);
  // compute the size of the c_i structure
  c_i_size = sizeof(PLI_INT32);
  // send c_i over pipe
  c_i_size = write (f_i, &c_i.value.integer, c_i_size);
 
  // grab argument d_i
  argh = vpi_scan(args_iter);
  d_i.format = vpiVectorVal;
  vpi_get_value(argh, &d_i);
  // compute the size of the d_i structure
  d_i_size = vpi_get(vpiSize, argh);
  d_i_size = (d_i_size-1)/(8*sizeof(PLI_INT32))+1;
  d_i_size =  d_i_size*sizeof(struct t_vpi_vecval);
  // send d_i over pipe
  d_i_size = write (f_i,  d_i.value.vector,  d_i_size);

  // grab argument d_o
  argh = vpi_scan(args_iter);
  d_o.format = vpiVectorVal;
  vpi_get_value(argh, &d_o);
  // compute the size of the d_o structure
  d_o_size = vpi_get(vpiSize, argh);
  d_o_size = (d_o_size-1)/(8*sizeof(PLI_INT32))+1;
  d_o_size =  d_o_size*sizeof(struct t_vpi_vecval);
  // receive d_i over pipe
  d_o_size = read  (f_o,  d_o.value.vector,  d_o_size);
  // put d_o signals
  vpi_put_value(argh, &d_o, NULL, vpiNoDelay);

  // grab argument c_o
  argh = vpi_scan(args_iter);
  c_o.format = vpiIntVal;
  vpi_get_value(argh, &c_o);
  // compute the size of the c_o structure
  c_o_size = sizeof(PLI_INT32);
  // receive c_i over pipe
  c_o_size = read  (f_o, &c_o.value.integer, c_o_size);
  // put c_o signals
  vpi_put_value(argh, &c_o, NULL, vpiNoDelay);

  // Cleanup
  vpi_free_object(args_iter);

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
  tf_data.compiletf   = NULL;
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
  tf_data.compiletf   = NULL;
  tf_data.sizetf      = NULL;
  tf_data.user_data   = NULL;
  vpi_register_systf(&tf_data);
}

void (*vlog_startup_routines[])() = {
  interface_init_register,
  interface_event_register,
  0
};
