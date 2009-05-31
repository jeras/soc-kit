#include <fcntl.h>
#include <unistd.h>

#include <stdio.h>

// ifnterface FIFO file descriptors
int f_o, f_i;

int interface_exchange (void *, unsigned int,
                        void *, unsigned int,
                        void *, unsigned int,
                        void *, unsigned int);

