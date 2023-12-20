ifdef CROSS_TC
	# NOTE: If we have a CROSS_TC toolchain w/ CC set to Clang,
	#       assume we know what we're doing, and that everything is setup the right way already (i.e., via x-compile.sh tc env clang)...
	ifneq "$(CC)" "clang"
		CC:=$(CROSS_TC)-gcc
		CXX:=$(CROSS_TC)-g++
		STRIP:=$(CROSS_TC)-strip
		# NOTE: This relies on GCC plugins!
		#       Enforce AR & RANLIB to point to their real binary and not the GCC wrappers if your TC doesn't support that!
		AR:=$(CROSS_TC)-gcc-ar
		RANLIB:=$(CROSS_TC)-gcc-ranlib
	endif
else ifdef CROSS_COMPILE
	CC:=$(CROSS_COMPILE)cc
	CXX:=$(CROSS_COMPILE)cxx
	STRIP:=$(CROSS_COMPILE)strip
	AR:=$(CROSS_COMPILE)gcc-ar
	RANLIB:=$(CROSS_COMPILE)gcc-ranlib
else
	CC?=gcc
	CXX?=g++
	STRIP?=strip
	AR?=gcc-ar
	RANLIB?=gcc-ranlib
endif

SHELL := bash -O extglob
TRUNK?=$(PWD)

CFLAGS+=-Wno-deprecated
ifeq ($(DEBUG),1)
	CFLAGS += -DDEBUG_TRACE
	ENABLE_DB_LOGGING=1
endif

ifeq ($(ENABLE_DB_LOGGING),1)
	CFLAGS += -DENABLE_DB_LOGGING
endif

ifeq ($(FAKE_ROOT),1)
	CFLAGS += -DFAKE_ROOT
endif

ifdef ALT_SHELL
	CFLAGS += -DALT_SHELL=\\\"$(ALT_SHELL)\\\"
endif

COMBINED_BUILD=1
ifeq ($(REVERSE_CONNECT),1)
	COMBINED_BUILD=0
	CLI_CFLAGS += -DCLI_REVERSE_CONNECT
	SVR_CFLAGS += -DSVR_REVERSE_CONNECT
endif

ifeq ($(BUILDSTATIC),1)
	LDFLAGS+="-static"
endif

CLI_CFLAGS += $(CFLAGS)
SVR_CFLAGS += $(CFLAGS)

DROPBEAR=dropbear
SCP=scp
DBCLIENT=dbclient

DB_SERVER_STAMP=.db_server
DB_CLIENT_STAMP=.db_client
CONFIG_CLI_STAMP=.config_cli_stamp
CONFIG_SVR_STAMP=.config_svr_stamp

CONFIG_OPTIONS=--disable-syslog --disable-zlib --disable-pam --disable-shadow


all:$(DB_SERVER_STAMP) $(DB_CLIENT_STAMP)


client:$(DB_CLIENT_STAMP)

server:$(DB_SERVER_STAMP)

db_clean:
	-make -C dropbear_src clean

$(DB_SERVER_STAMP): $(CONFIG_SVR_STAMP) dropbear_src/$(DROPBEAR)
	cp dropbear_src/$(DROPBEAR) .
	touch $@
	$(STRIP) $(DROPBEAR)

$(DB_CLIENT_STAMP): $(CONFIG_CLI_STAMP) dropbear_src/$(SCP) dropbear_src/$(DBCLIENT)
	cp $ dropbear_src/$(SCP) dropbear_src/$(DBCLIENT) .
	touch $@
	$(STRIP) $(SCP)


$(CONFIG_CLI_STAMP):
	cd dropbear_src && \
	./configure --verbose LDFLAGS=$(LDFLAGS) $(CONFIG_OPTIONS) --host=$(HOST) CFLAGS="$(CLI_CFLAGS)"
	touch dropbear_src/*.c
	touch dropbear_src/*.h
	touch $@

$(CONFIG_SVR_STAMP):
	cd dropbear_src && \
	./configure --verbose LDFLAGS=$(LDFLAGS) $(CONFIG_OPTIONS) --host=$(HOST) CFLAGS="$(SVR_CFLAGS)"
	touch dropbear_src/*.c
	touch dropbear_src/*.h
	touch $@

multi: $(CONFIG_SVR_STAMP)
	make -C dropbear_src PROGRAMS="dropbear dbclient scp" MULTI=1 
	$(STRIP) dropbear_src/dropbearmulti
	mkdir dist
	cp dropbear_src/dropbearmulti dist/dropbearmulti

clean:
	-rm -f $(DB_SERVER_STAMP) $(DB_CLIENT_STAMP) $(CONFIG_CLI_STAMP) $(CONFIG_SVR_STAMP) dist
	-rm $(DROPBEAR)
	-rm $(SCP)
	-rm $(DBCLIENT)
	make -C dropbear_src distclean

