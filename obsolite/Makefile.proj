# ---- Will be extracted and used by remote.sh ----
#:REMOTE-INFO-BEGIN
# TARGETHOST   deployment/test host or IP address, e.g. user@1.2.3.4
TARGETHOST		= usre@1.2.3.4
# UPLOADDIR    top directory for the source; everything from '.' will be synced
#              with rsync to there! The directory must exist
UPLOADDIR		= /path/to/some/source_upload_dir

# Path to local and remote rsync
RRSYNC			= /usr/bin/rsync
LRSYNC			= /usr/bin/rsync
# Path to local ssh
SSH				= /usr/bin/ssh
# Arguments to rsync, EXCLUDE_FILE will be appended
EXCLUDE_FILE	= rsync_exclude.txt
RSYNC_ARGS		= -avzH --exclude-from
SSH_ARGS		=  -Tq -o LogLevel=error 

# This directory (source)
SRCDIR			= .

# Project directory -- see project_template
PROJDIR			= ../../my_project
#:REMOTE-INFO-END

#
# Generic Makefile
#
# Default to build with multiple instances for speed
MAKEFLAGS =+ -j

# Beware, This will create this application
# binary based on the current directory name.
TARGET  := $(shell basename `pwd`)

# Create the target lists
SOURCES := $(wildcard *.c)
SOURCES += $(wildcard lib/*.c)
SOURCES += $(wildcard modules/*.c)
OBJECTS := $(patsubst %.c,%.o,$(SOURCES))
DEPENDS := $(SOURCES:.c=.d)

VERSION := $(shell git describe --long --dirty --tags --always 2>/dev/null)

CFLAGS += -I./include
CFLAGS += -g -Wall
CFLAGS += -Werror
LDLIBS += -lncurses -lpanel

## Define the Version for the Application
#CFLAGS += -DVERSION=\"$(VERSION)\"
# version.h is made by remote.sh locally as git may not ba available on the compile host

# Top level Build Rule
all: ${TARGET}

# Manage Dependancy Generation
# These dependency rules have been generated based on guidance from
#    http://mad-scientist.net/make/autodep.html
# The sed extension adds the dependancies to the .d file as well
# Note its important here not to use the usual 's/find/replace/g'
# as paths of the files include the '/' character
%.d: %.c
	@$(CC) -M $(CFLAGS) $(CPPFLAGS) -MQ '$*.o' $< | sed 's|$*\.o[ :]*|&$@ |g' > $@

-include $(DEPENDS)

# Build the application
$(TARGET): $(OBJECTS)
 	@$(CC) -o $@ $^ $(LDLIBS)
 
test: $(TARGET)
 	valgrind --verbose --leak-check=full --show-leak-kinds=all $(TARGET)
 
clean:
 	@rm -f $(TARGET) $(OBJECTS) $(DEPENDS)
 
help: printvars helpsummary
 
helpsummary:
 	@echo "TARGET  : $(TARGET)"
 	@echo "VERSION : $(VERSION)"
 	@echo "SOURCES : $(SOURCES)"
 	@echo "OBJECTS : $(OBJECTS)"
 	@echo "DEPENDS : $(DEPENDS)"
 	@echo "CFLAGS  : $(CFLAGS)"
 	@echo "LDLIBS  : $(LDLIBS)"
 
# A useful debug Make Target - found from
# http://lists.gnu.org/archive/html/help-make/2005-08/msg00137.html
.PHONY: printvars
printvars:
 	@$(foreach V,$(sort $(.VARIABLES)), \
 	$(if $(filter-out environment% default automatic, \
	$(origin $V)),$(warning $V=$($V) ($(value $V)))))
