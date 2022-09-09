# Build options can be changed by modifying the makefile or by building with 'make SETTING=value'.
# It is also possible to override the settings in Defaults in a file called .make_options as 'SETTING=value'.

-include .make_options

#### Defaults ####

# If COMPARE is 1, check the output md5sum after building
COMPARE ?= 1
# If NON_MATCHING is 1, define the NON_MATCHING C flag when building
NON_MATCHING ?= 0
# if WERROR is 1, pass -Werror to CC_CHECK, so warnings would be treated as errors
WERROR ?= 0
# Check code syntax with host compiler
RUN_CC_CHECK ?= 1
# Dump build object files
OBJDUMP_BUILD ?= 0
# Number of threads to disassmble, extract, and compress with
# N_THREADS ?= $(shell nproc)


BASEROM      := SLUS_21678/slus_216.78
TARGET       := slus_216.78
# CHECK        ?= 1
# VERBOSE      ?= 0

# Fail early if baserom does not exist
ifeq ($(wildcard $(BASEROM)),)
$(error Baserom `$(BASEROM)' not found.)
endif


### Output ###

BUILD_DIR := build
# ROM       := $(BUILD_DIR)/$(TARGET).z64
ELF       := $(BUILD_DIR)/$(TARGET).elf
LD_SCRIPT := $(BUILD_DIR)/$(TARGET).ld
LD_MAP    := $(BUILD_DIR)/$(TARGET).map


### Tools ###

ifeq ($(OS),Windows_NT)
    OS = windows
else
    UNAME_S := $(shell uname -s)
    ifeq ($(UNAME_S),Linux)
        OS = linux
    endif
    ifeq ($(UNAME_S),Darwin)
        OS = macos
    endif
endif

PYTHON     ?= python3
SPLAT_YAML ?= slus_216.78.yaml
SPLAT      ?= $(PYTHON) tools/splat/split.py $(SPLAT_YAML)

CROSS    := mips-linux-gnu-
AS       := $(CROSS)as
LD       := $(CROSS)ld
OBJDUMP  := $(CROSS)objdump
OBJCOPY  := $(CROSS)objcopy
STRIP    := $(CROSS)strip

# CC       := tools/ido_recomp/$(OS)/7.1/cc
CC_HOST  := clang
CPP      := cpp -P


# create asm directories
$(shell mkdir -p asm $(BUILD_DIR)/auto)


### Targets ###

all: $(ELF)

# -include $(DEPENDS)

clean:
	$(RM) -rf build

distclean: clean
	$(RM) -rf asm
	$(RM) -rf assets

setup: split

split:
	$(SPLAT) $(SPLAT_YAML)

### Make Settings ###

# Prevent removing intermediate files
.SECONDARY:

# Specify which targets don't have a corresponding file
.PHONY: all clean distclean setup split

# Remove built-in implicit rules to improve performance
MAKEFLAGS += --no-builtin-rules

# Print target for debugging
print-% : ; $(info $* is a $(flavor $*) variable set to [$($*)]) @true
