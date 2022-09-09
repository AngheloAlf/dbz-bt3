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
OBJDUMP_BUILD ?= 1
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
# ROM       := build/$(TARGET).z64
ELF       := build/$(TARGET).elf
LD_SCRIPT := build/$(TARGET).ld
LD_MAP    := build/$(TARGET).map


### Compiler Options ###

ASFLAGS      := -G 0 -I include -EL -mtune=r5900 -march=r5900
# CFLAGS       := -G 0 -non_shared -Xfullwarn -Xcpluscomm -Wab,-r4300_mul
CPPFLAGS     := -P -I include
LDFLAGS      := -EL --no-check-sections --accept-unknown-input-arch --emit-relocs
# OPTFLAGS     := -O2

IINC       := -Iinclude -Isrc -Iassets -Ibuild -I.

ifeq ($(KEEP_MDEBUG),0)
  RM_MDEBUG = $(OBJCOPY) --remove-section .mdebug $@
else
  RM_MDEBUG = @:
endif

# Check code syntax with host compiler
ifneq ($(RUN_CC_CHECK),0)
	CHECK_WARNINGS ?= -Wall -Wextra -Wno-unknown-pragmas -Wno-unused-label
	CHECK_WARNINGS += -Wno-unused-parameter -Wno-unused-variable
	CC_CHECK       := clang -fno-builtin -fsyntax-only -fdiagnostics-color -D NON_MATCHING $(IINC) -nostdinc $(CHECK_WARNINGS)
	ifneq ($(WERROR), 0)
		CC_CHECK += -Werror
	endif
else
	CC_CHECK := @:
endif

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
		MAKE=gmake
		CPPFLAGS += -xc++
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
CPP      := cpp

# Use relocations and abi fpr names in the dump
OBJDUMP_FLAGS := --disassemble --reloc --disassemble-zeroes -Mreg-names=32

ifneq ($(OBJDUMP_BUILD), 0)
  OBJDUMP_CMD = $(OBJDUMP) $(OBJDUMP_FLAGS) $@ > $(@:.o=.s)
  OBJCOPY_BIN = $(OBJCOPY) -O binary $@ $@.bin
else
  OBJDUMP_CMD = @:
  OBJCOPY_BIN = @:
endif

# create asm directories
$(shell mkdir -p asm bin build/auto)


# SRC_DIRS		:= $(shell find src -type d)
ASM_DIRS		:= $(shell find asm -type d)
BIN_DIRS		:= $(shell find bin -type d)

C_FILES			:= $(foreach dir,$(SRC_DIRS),$(wildcard $(dir)/*.c))
S_FILES			:= $(foreach dir,$(ASM_DIRS),$(wildcard $(dir)/*.s))
BIN_FILES		:= $(foreach dir,$(BIN_DIRS),$(wildcard $(dir)/*.bin))
O_FILES       	:= $(foreach f,$(C_FILES:.c=.c.o),build/$f) \
                   $(foreach f,$(S_FILES:.s=.s.o),build/$f) \
                   $(foreach f,$(BIN_FILES:.bin=.bin.o),build/$f) \

### Targets ###

all: $(ELF)

# -include $(DEPENDS)

clean:
	$(RM) -rf build

distclean: clean
	$(RM) -rf asm
	$(RM) -rf bin

setup: split

split:
	$(SPLAT) $(SPLAT_YAML)


$(ELF): $(O_FILES) $(LD_SCRIPT) build/undefined_syms.txt build/undefined_funcs.txt
	$(LD) $(LDFLAGS) -T build/undefined_syms.txt -T build/undefined_funcs.txt -T build/auto/undefined_syms_auto.txt -T build/auto/undefined_funcs_auto.txt -T $(LD_SCRIPT) -Map $(LD_MAP) -o $@


build/undefined_syms.txt: undefined_syms.txt
	$(CPP) $(CPPFLAGS) $< > $@
build/undefined_funcs.txt: undefined_funcs.txt
	$(CPP) $(CPPFLAGS) $< > $@

# Assemble .s files with modern gnu as
build/asm/%.s.o: asm/%.s
	@mkdir -p $(shell dirname $@)
	$(AS) $(ASFLAGS) -o $@ $<
	$(OBJDUMP_CMD)

build/assets/%.c.o: assets/%.c
	@mkdir -p $(shell dirname $@)
	$(CC) -c $(CFLAGS) $(MIPS_VERSION) $(OPTFLAGS) -o $@ $<
	$(OBJCOPY_BIN)
	$(RM_MDEBUG)

build/%.bin.o: %.bin
	@mkdir -p $(shell dirname $@)
	$(OBJCOPY) -I binary -O elf32-little $< $@


### Make Settings ###

# Prevent removing intermediate files
.SECONDARY:

# Specify which targets don't have a corresponding file
.PHONY: all clean distclean setup split

# Remove built-in implicit rules to improve performance
MAKEFLAGS += --no-builtin-rules

# Print target for debugging
print-% : ; $(info $* is a $(flavor $*) variable set to [$($*)]) @true
