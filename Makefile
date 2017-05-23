
SUBDIRS:= common server client

all: $(SUBDIRS)
	@for dir in $(SUBDIRS); do make -C $$dir || exit"$$?"; done

clean: $(SUBDIRS)
	@for dir in $(SUBDIRS); do make -C $$dir clean; done
