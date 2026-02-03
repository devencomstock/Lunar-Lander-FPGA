# Select which part's rules to use:
# Lunar Lander Part I and Lunar Lander Part II
# PART ?= 1

export PATH := /home/shay/a/ece270/bin:$(PATH)
export LD_LIBRARY_PATH := /home/shay/a/ece270/lib:$(LD_LIBRARY_PATH)

YOSYS=yosys
NEXTPNR=nextpnr-ice40
SHELL=bash

.PHONY: help
.DEFAULT_GOAL:= help

ifneq ($(MAKECMDGOALS),)
  ifeq ($(filter help clean, $(MAKECMDGOALS)),)
	# If PART not set OR invalid, print help then exit
    ifndef PART
      $(info Usage: make PART=1 <target> or make PART=2 <target>)
      $(info Example: make PART=1 verify_ll_control or make PART=2 verify_ll_display) 
      $(error Missing PART. Specify PART=1 or PART=2.)
    endif
    ifeq ($(filter $(PART),1 2),)
      $(info Invalid PART='$(PART)'. Valid options are 1 or 2.)
      $(info Usage: make PART=1 <target> or make PART=2 <target>)
      $(info Example: make PART=1 verify_ll_control or make PART=2 verify_ll_display) 
      $(error Invalid PART value. Specify PART=1 or PART=2.)
    endif
  endif
endif

help:
	@echo "============================================"
	@echo " Lunar Lander Makefile Help Menu"
	@echo "============================================"
	@echo "How to use this script:"
	@echo
	@echo "PART selects which portion of the project you are working on:"
	@echo "  PART=1  -> Part 1 (Lunar Lander Part 1: adders from the lab assignment / core logic / bcd arithmetic / ll_alu / ll_memory / ll_control)"
	@echo "  PART=2  -> Part 2 (Lunar Lander Part 2: ll_display and top-level lunarlander integration)"
	@echo
	@echo "  make help -> Opens this help menu. Displays all the commands to test your lunar lander module."
	@echo "  make clean ->  Clean the current workspace and build files"
	@echo
	@echo "Usage examples for Lab Assignment and PART 1:"
	@echo "  make PART=1 verify_fa"
	@echo "  make PART=1 verify_fa4"
	@echo "  make PART=1 verify_bcdadd1"
	@echo "  make PART=1 verify_bcdadd4"
	@echo "  make PART=1 verify_bcd9comp1"
	@echo "  make PART=1 verify_bcdaddsub4"
	@echo "  make PART=1 verify_ll_alu"
	@echo "  make PART=1 verify_ll_control"
	@echo "  make PART=1 verify_ll_memory"
	@echo "  make PART=1 cram         # flash Part 1 design to FPGA (SRAM)"
	@echo
	@echo "Usage examples for PART 2:"
	@echo "  make PART=2 verify_ll_display"
	@echo "  make PART=2 verify_lunarlander"
	@echo "  make PART=2 view_ll_display"
	@echo "  make PART=2 view_lunarlander"
	@echo "  make PART=2 cram         # flash Part 2 design to FPGA (SRAM)"
	@echo
	@echo "If you run 'make' with no PART specified, this help is shown automatically."
	@echo "To change part, always run:  make PART=1 <target>  or  make PART=2 <target>."
	@echo

######################## LUNAR LANDER PART 1: ##########################
# PART 1 Rules: 
ifeq ($(PART),1)

PROJ	= lab10
PINMAP 	= pinmap.pcf
TCLPREF = addwave.gtkw
SRC	    = top.sv
ICE   	= ice40hx8k.sv
CHK 	= check.bin
DEM 	= demo.bin
JSON    = ll.json
#SUP     = support/moddefs.sv
UART	= uart/uart.v uart/uart_tx.v uart/uart_rx.v
FILES   = $(ICE) $(SRC) $(UART)
TRACE	= $(PROJ).vcd
BUILD   = ./build

DEVICE  = 8k
TIMEDEV = hx8k
FOOTPRINT = ct256

all: cram

#########################
# Flash to FPGA
$(BUILD)/$(PROJ).json : $(ICE) $(SRC) $(PINMAP) Makefile
	# lint with Verilator
	verilator --lint-only --top-module top $(SRC) $(SUP)
	# if build folder doesn't exist, create it
	mkdir -p $(BUILD)
	# synthesize using Yosys
	# $(YOSYS) -p "read_json $(JSON); read_verilog -sv -noblackbox $(FILES); synth_ice40 -top ice40hx8k -json $(BUILD)/$(PROJ).json"
	$(YOSYS) -p "read_verilog -sv -noblackbox $(FILES); \
                hierarchy -top ice40hx8k; \
                synth_ice40 -top ice40hx8k; \
                opt_clean -purge; clean -purge; \
                write_json $(BUILD)/$(PROJ).json"

$(BUILD)/$(PROJ).asc : $(BUILD)/$(PROJ).json
	# Place and route using nextpnr
	$(NEXTPNR) --hx8k --package ct256 --pcf $(PINMAP) --asc $(BUILD)/$(PROJ).asc --json $(BUILD)/$(PROJ).json 2> >(sed -e 's/^.* 0 errors$$//' -e '/^Info:/d' -e '/^[ ]*$$/d' 1>&2)

$(BUILD)/$(PROJ).bin : $(BUILD)/$(PROJ).asc
	# Convert to bitstream using IcePack
	icepack $(BUILD)/$(PROJ).asc $(BUILD)/$(PROJ).bin

#########################
# Verification Suite
VFLAGS = --build --cc --exe --trace-fst --Mdir build

verify_fa: top.sv tb_prelab.cpp
	@echo ========================================
	@echo Compiling and verifying fa...
	yosys -p "read_verilog -sv top.sv; synth_ice40 -top fa" || (echo "Failed to synthesize fa"; exit 1)
	@rm -rf build
	verilator $(VFLAGS) --top-module fa -CFLAGS -DFA top.sv tb_prelab.cpp 1>/dev/null
	./build/Vfa

verify_fa4: top.sv tb_prelab.cpp
	@echo ========================================
	@echo Compiling and verifying fa4...
	yosys -p "read_verilog -sv top.sv; synth_ice40 -top fa4" || (echo "Failed to synthesize fa4"; exit 1)
	@rm -rf build
	verilator $(VFLAGS) --top-module fa4 -CFLAGS -DFA4 top.sv tb_prelab.cpp 1>/dev/null
	./build/Vfa4

verify_bcdadd1: top.sv tb_prelab.cpp
	@echo ========================================
	@echo Compiling and verifying bcdadd1...
	yosys -p "read_verilog -sv top.sv; synth_ice40 -top bcdadd1" || (echo "Failed to synthesize bcdadd1"; exit 1)
	@rm -rf build
	verilator $(VFLAGS) --top-module bcdadd1 -CFLAGS -DBCDADD1 top.sv tb_prelab.cpp 1>/dev/null
	./build/Vbcdadd1

verify_bcdadd4: top.sv tb_prelab.cpp
	@echo ========================================
	@echo Compiling and verifying bcdadd4...
	yosys -p "read_verilog -sv top.sv; synth_ice40 -top bcdadd4" || (echo "Failed to synthesize bcdadd4"; exit 1)
	@rm -rf build
	verilator $(VFLAGS) --top-module bcdadd4 -CFLAGS -DBCDADD4 top.sv tb_prelab.cpp 1>/dev/null
	./build/Vbcdadd4

verify_bcd9comp1: top.sv tb_prelab.cpp
	@echo ========================================
	@echo Compiling and verifying bcd9comp1...
	yosys -p "read_verilog -sv top.sv; synth_ice40 -top bcd9comp1" || (echo "Failed to synthesize bcd9comp1"; exit 1)
	@rm -rf build
	verilator $(VFLAGS) --top-module bcd9comp1 -CFLAGS -DBCD9COMP1 top.sv tb_prelab.cpp 1>/dev/null
	./build/Vbcd9comp1

verify_bcdaddsub4: top.sv tb_prelab.cpp
	@echo ========================================
	@echo Compiling and verifying bcdaddsub4...
	yosys -p "read_verilog -sv top.sv; synth_ice40 -top bcdaddsub4" || (echo "Failed to synthesize bcdaddsub4"; exit 1)
	@rm -rf build
	verilator $(VFLAGS) --top-module bcdaddsub4 -CFLAGS -DBCDADDSUB4 top.sv tb_prelab.cpp 1>/dev/null
	./build/Vbcdaddsub4

verify_ll_alu: src/top.sv sim/tb_part1.cpp
	verilator --lint-only -Wno-MULTITOP src/top.sv
	yosys -p "read_verilog -sv src/top.sv; synth_ice40 -top ll_alu" || (echo "Failed to synthesize ll_alu"; exit 1)
	@echo ========================================
	@echo Compiling and verifying ll_alu...
	@rm -rf build
	verilator $(VFLAGS) --top-module ll_alu -CFLAGS -DLL_ALU src/top.sv sim/tb_part1.cpp 1>/dev/null
	./build/Vll_alu

verify_ll_memory: src/top.sv sim/tb_part1.cpp
	verilator --lint-only -Wno-MULTITOP src/top.sv
	yosys -p "read_verilog -sv src/top.sv; synth_ice40 -top ll_memory" || (echo "Failed to synthesize ll_memory"; exit 1)
	@echo ========================================
	@echo Compiling and verifying ll_memory...
	@rm -rf build
	verilator $(VFLAGS) --top-module ll_memory -CFLAGS -DLL_MEMORY src/top.sv sim/tb_part1.cpp 1>/dev/null
	./build/Vll_memory

verify_ll_control: src/top.sv sim/tb_part1.cpp
	verilator --lint-only -Wno-MULTITOP src/top.sv
	yosys -p "read_verilog -sv src/top.sv; synth_ice40 -top ll_control" || (echo "Failed to synthesize ll_control"; exit 1)
	@echo ========================================
	@echo Compiling and verifying ll_control...
	@rm -rf build
	verilator $(VFLAGS) --top-module ll_control -CFLAGS -DLL_CONTROL src/top.sv sim/tb_part1.cpp 1>/dev/null
	./build/Vll_control

#########################
# ice40 Specific Targets
check: $(CHK)
	iceprog -S $(CHK)
	
demo:  $(DEM)
	iceprog -S $(DEM)

flash: $(BUILD)/$(PROJ).bin
	iceprog $(BUILD)/$(PROJ).bin

cram: $(BUILD)/$(PROJ).bin
	iceprog -S $(BUILD)/$(PROJ).bin

time: $(BUILD)/$(PROJ).asc
	icetime -p $(PINMAP) -P $(FOOTPRINT) -d $(TIMEDEV) $<

#########################
# Clean Up
#clean:
#	rm -rf build/ *.fst verilog.log

endif # PART == 1


######################## LUNAR LANDER PART 2: ##########################
# PART 2 Rules: 
ifeq ($(PART),2)

PROJ    = lab11
PINMAP  = pinmap.pcf
TCLPREF = addwave.gtkw
SRC         = top.sv
ICE     = ice40hx8k.sv
CHK     = check.bin
DEM     = demo.bin
JSON    = ll.json
SUP     = support/cells_*.v
UART    = uart/uart.v uart/uart_tx.v uart/uart_rx.v
FILES   = $(ICE) $(SRC) $(UART)
TRACE   = $(PROJ).vcd
BUILD   = ./build

DEVICE  = 8k
TIMEDEV = hx8k
FOOTPRINT = ct256

all: cram
#########################
# Flash to FPGA
$(BUILD)/$(PROJ).json : $(ICE) $(SRC) $(PINMAP) Makefile
        # lint with Verilator
	verilator --lint-only --top-module top $(SRC)
        # if build folder doesn't exist, create it
	mkdir -p $(BUILD)
        # synthesize using Yosys
        # $(YOSYS) -p "read_verilog -sv -noblackbox $(FILES); synth_ice40 -top ice40hx8k -json $(BUILD)/$(PROJ).json"
	$(YOSYS) -p "read_verilog -sv -noblackbox $(FILES); \
                hierarchy -top ice40hx8k; \
		synth_ice40 -top ice40hx8k; \
                opt_clean -purge; clean -purge; \
                write_json $(BUILD)/$(PROJ).json"
$(BUILD)/$(PROJ).asc : $(BUILD)/$(PROJ).json
        # Place and route using nextpnr
	$(NEXTPNR) --hx8k --package ct256 --pcf $(PINMAP) --asc $(BUILD)/$(PROJ).asc --json $(BUILD)/$(PROJ).json 2> >(sed -e 's/^.* 0 errors$$//' -e '/^Info:/d' -e '/^[ ]*$$/d' 1>&2)

$(BUILD)/$(PROJ).bin : $(BUILD)/$(PROJ).asc
        # Convert to bitstream using IcePack
	icepack $(BUILD)/$(PROJ).asc $(BUILD)/$(PROJ).bin

#########################

# Verification Suite
VFLAGS = --build --cc --exe --trace-fst --Mdir build

verify_ll_display: src/top.sv sim/tb_part2.cpp
	verilator --lint-only -Wno-MULTITOP src/top.sv
	@echo ========================================
	@echo Compiling and verifying ll_display...
	@rm -rf build
	yosys -p "read_verilog -sv src/top.sv; synth_ice40 -top ll_display" || (echo "Failed to synthesize ll_display"; exit 1)
	verilator $(VFLAGS) --top-module ll_display -CFLAGS -DLL_DISPLAY src/top.sv sim/tb_part2.cpp 1>/dev/null
	./build/Vll_display

verify_lunarlander: src/top.sv sim/tb_ll.sv
	$(YOSYS) -V
	verilator --lint-only -Wno-MULTITOP src/top.sv
	@echo ========================================
	@echo Compiling and verifying lunarlander...
	@rm -rf build
	@mkdir -p build
	yosys -p "read_verilog -sv -noblackbox $(FILES); synth_ice40 -top lunarlander; write_verilog build/ll.v"
	iverilog -g2012 sim/tb_ll.sv build/ll.v $(SUP) -o build/sim
	./build/sim

view_ll_display: verify_ll_display
	gtkwave gtkw/ll_display.gtkw

view_lunarlander: verify_lunarlander
	gtkwave gtkw/lunarlander.gtkw

#########################
# ice40 Specific Targets
check: $(CHK)
	iceprog -S $(CHK)

demo:  $(DEM)
	iceprog -S $(DEM)

flash: $(BUILD)/$(PROJ).bin
	iceprog $(BUILD)/$(PROJ).bin

cram: $(BUILD)/$(PROJ).bin
	iceprog -S $(BUILD)/$(PROJ).bin

time: $(BUILD)/$(PROJ).asc
	icetime -p $(PINMAP) -P $(FOOTPRINT) -d $(TIMEDEV) $<

#########################
# Clean Up
#clean:
#	rm -rf build/ *.fst *.vcd verilog.log abc.history

endif # PART == 2

clean:
	rm -rf build/ *.fst *.vcd verilog.log abc.history
