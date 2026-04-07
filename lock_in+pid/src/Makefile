CC=$(CROSS_COMPILE)gcc
RM=rm

OBJECTS=main.o fpga.o worker.o calib.o fpga_awg.o generate.o fpga_pid.o pid.o fpga_lock.o lock.o

CFLAGS+= -Wall -Werror -g -fPIC $(INCLUDE)
LDFLAGS=-shared

# added by Andi to deactivate LEDs
# note: neither LIBS nor LDLIBS option work.
CFLAGS+=-I/opt/redpitaya/include
LDFLAGS+=-L/opt/redpitaya/lib -lrp-hw
# end added by Andi


CONTROLLER     = ../controllerhf.so

all: $(CONTROLLER)

$(CONTROLLER): $(OBJECTS)
	$(CC) -o $(CONTROLLER) $(OBJECTS) $(CFLAGS) $(LDFLAGS)
	-$(RM) -f $(OBJECTS)

clean:
	-$(RM) -f $(OBJECTS)
