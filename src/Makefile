
ifdef MINGW_PREFIX
MINGW=1
else
 OS=$(shell uname)
 ifeq ($(OS),Darwin)
 MACOS=1
 else
 LINUX=1
 endif
endif

# Lua version
LUAVER?=$(shell lua -e 'print(string.match(_VERSION, "%d+%.%d+") or "5.3")')
ifeq ($(LUAVER),)
# lua-interpreter not found
LUAVER=5.3
endif

ifdef MACOS
DLL_EXT=dylib
endif

ifdef LINUX
DLL_EXT=so
endif

ifdef MINGW
DLL_EXT=dll
endif

# Base install directory
ifdef MACOS
PREFIX?=/usr/local
endif

ifdef LINUX
PREFIX?=/usr/local
endif

ifdef MINGW
PREFIX?=$(MINGW_PREFIX)
endif

# Directory where to install Lua modules
L_DIR=$(PREFIX)/share/lua/$(LUAVER)
# Directory where to install Lua C modules
C_DIR=$(PREFIX)/lib/lua/$(LUAVER)
# Directory where to install C headers
H_DIR=$(PREFIX)/include
# Directory where to install C libraries
S_DIR=$(PREFIX)/lib

ifeq ($(D),1)
DEBUG=1
endif

Tgt	:= moonnuklear
Src := $(wildcard *.c)
Objs := $(Src:.c=.o)
 
COPT	+= -O2
#COPT	+= -O0 -g
#COPT	+= -m32
COPT	+= -Wall -Wextra -Wpedantic
COPT    += -std=gnu99
COPT 	+= -DLUAVER=$(LUAVER)

ifdef MACOS
COPT    += -fpic
COPT    += -DMACOS
COPT	+= -DCOMPAT53_PREFIX=moonnuklear_compat_
INCDIR = -I/usr/include -I/usr/include/lua$(LUAVER) -I$(PREFIX)/include/lua$(LUAVER) -I./nuklear
LIBDIR = -L/usr/lib -L$(PREFIX)/lib
LIBS = -llua$(LUAVER)
endif

ifdef LINUX
COPT    += -fpic
COPT	+= -DLINUX
INCDIR = -I./nuklear -I/usr/include/lua$(LUAVER)
endif

ifdef MINGW
COPT	+= -DMINGW
INCDIR = -I./nuklear
LIBS = -llua
endif

ifdef DEBUG
COPT	+= -DDEBUG
COPT 	+= -Wshadow -Wsign-compare -Wundef -Wwrite-strings
COPT	+= -Wdisabled-optimization -Wdeclaration-after-statement
COPT    += -Wmissing-prototypes -Wstrict-prototypes -Wnested-externs
COPT    += -Wc++-compat -Wold-style-definition
endif

override CFLAGS = $(COPT) $(INCDIR)

default: build

where:
	@echo "PREFIX="$(PREFIX)
	@echo "LUAVER="$(LUAVER)
	@echo $(L_DIR)
	@echo $(C_DIR)
	@echo $(H_DIR)
	@echo $(S_DIR)

clean:
	@-rm -f *.so *.dll *.o *.err *.map *.S *~ *.log *.dylib
	@-rm -f $(Tgt).symbols

install:
	@-mkdir -pv $(H_DIR)
	@-mkdir -pv $(C_DIR)
	@-mkdir -pv $(S_DIR)
	@-mkdir -pv $(L_DIR)
	@-cp -fpv $(Tgt).h $(H_DIR)
	@-cp -fpvr ../$(Tgt) $(L_DIR)
ifdef MACOS 
	@-cp -fpv $(Tgt).$(DLL_EXT) $(C_DIR)
	@-ln -fsv $(C_DIR)/$(Tgt).$(DLL_EXT) $(C_DIR)/$(Tgt).so 
	@-ln -fsv $(C_DIR)/$(Tgt).$(DLL_EXT) $(S_DIR)/lib$(Tgt).$(DLL_EXT)
endif
ifdef LINUX
	@-cp -fpv $(Tgt).$(DLL_EXT) $(C_DIR)
	@-ln -fsv $(C_DIR)/$(Tgt).$(DLL_EXT) $(S_DIR)/lib$(Tgt).$(DLL_EXT)
endif
ifdef MINGW
	@-cp -fpv $(Tgt).dll $(C_DIR)
endif

uninstall:
	@-rm -f $(H_DIR)/$(Tgt).h
	@-rm -f $(C_DIR)/$(Tgt).$(DLL_EXT)
	@-rm -f $(S_DIR)/lib$(Tgt).$(DLL_EXT)
	@-rm -rf $(L_DIR)/$(Tgt)
	@-rm -f $(C_DIR)/$(Tgt).dll
	@-rm -f $(C_DIR)/$(Tgt).so

build:	clean $(Tgt) 

symbols: build
	@objdump -T $(Tgt).$(DLL_EXT) > $(Tgt).symbols

$(Tgt):		$(Objs)
ifdef MACOS
	@-$(CC) -shared -o $(Tgt).$(DLL_EXT) $(Objs) $(LIBDIR) $(LIBS)
endif
ifdef LINUX
	@-$(CC) -shared -o $(Tgt).$(DLL_EXT) $(Objs) $(LIBDIR) $(LIBS)
endif
ifdef MINGW
	@-$(CC) -shared -o $(Tgt).dll $(Objs) $(LIBDIR) $(LIBS)
endif
	@-rm -f $(Objs)
	@echo

