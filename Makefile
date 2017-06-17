
SUBDIRS:= core tinyxml server client test

all: $(SUBDIRS)
	@for dir in $(SUBDIRS); do make -C $$dir || exit"$$?"; done

clean: $(SUBDIRS)
	@for dir in $(SUBDIRS); do make -C $$dir clean; done
