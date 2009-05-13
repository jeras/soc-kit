# include  <vpi_user.h>

// initialization

static int interface_init_compiletf(char*user_data)
{
  return 0;
}

static int interface_init_calltf(char*user_data)
{
  vpi_printf("Hello, from interface_init!\n");
  return 0;
}

void interface_init_register()
{
  s_vpi_systf_data tf_data;

  tf_data.type      = vpiSysTask;
  tf_data.tfname    = "$interface_init";
  tf_data.calltf    = interface_init_calltf;
  tf_data.compiletf = interface_init_compiletf;
  tf_data.sizetf    = 0;
  tf_data.user_data = 0;
  vpi_register_systf(&tf_data);
}

// reset

static int interface_rst_compiletf(char*user_data)
{
  return 0;
}

static int interface_rst_calltf(char*user_data)
{
  vpi_printf("Hello, from interface_rst!\n");
  return 0;
}

void interface_rst_register()
{
  s_vpi_systf_data tf_data;

  tf_data.type      = vpiSysTask;
  tf_data.tfname    = "$interface_rst";
  tf_data.calltf    = interface_rst_calltf;
  tf_data.compiletf = interface_rst_compiletf;
  tf_data.sizetf    = 0;
  tf_data.user_data = 0;
  vpi_register_systf(&tf_data);
}

// clock

static int interface_clk_compiletf(char*user_data)
{
  return 0;
}

static int interface_clk_calltf(char*user_data)
{
  vpi_printf("Hello, from interface_clk!\n");
  return 0;
}

void interface_clk_register()
{
  s_vpi_systf_data tf_data;

  tf_data.type      = vpiSysTask;
  tf_data.tfname    = "$interface_clk";
  tf_data.calltf    = interface_clk_calltf;
  tf_data.compiletf = interface_clk_compiletf;
  tf_data.sizetf    = 0;
  tf_data.user_data = 0;
  vpi_register_systf(&tf_data);
}

// output

static int interface_o_compiletf(char*user_data)
{
  return 0;
}

static int interface_o_calltf(char*user_data)
{
  vpi_printf("Hello, from interface_o!\n");
  return 0;
}

void interface_o_register()
{
  s_vpi_systf_data tf_data;

  tf_data.type      = vpiSysTask;
  tf_data.tfname    = "$interface_o";
  tf_data.calltf    = interface_o_calltf;
  tf_data.compiletf = interface_o_compiletf;
  tf_data.sizetf    = 0;
  tf_data.user_data = 0;
  vpi_register_systf(&tf_data);
}

// input

static int interface_i_compiletf(char*user_data)
{
  return 0;
}

static int interface_i_calltf(char*user_data)
{
  vpi_printf("Hello, from interface_i!\n");
  return 0;
}

void interface_i_register()
{
  s_vpi_systf_data tf_data;

  tf_data.type      = vpiSysTask;
  tf_data.tfname    = "$interface_i";
  tf_data.calltf    = interface_i_calltf;
  tf_data.compiletf = interface_i_compiletf;
  tf_data.sizetf    = 0;
  tf_data.user_data = 0;
  vpi_register_systf(&tf_data);
}

void (*vlog_startup_routines[])() = {
  interface_init_register,
  interface_clk_register,
  interface_rst_register,
  interface_o_register,
  interface_i_register,
  0
};
