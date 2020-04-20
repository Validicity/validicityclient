PREFIX = /usr/local

all: ntag-driver

ntag-driver: ntag-driver.c
	gcc $^ -std=c99 -lfreefare -lnfc -o $@

.PHONY: install
install: ntag-driver
	mkdir -p $(DESTDIR)$(PREFIX)/bin
	cp $< $(DESTDIR)$(PREFIX)/bin/$<

.PHONY: uninstall
uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/ntag-driver

.PHONY: clean
clean:
	rm -f ntag-driver
	touch ntag-driver.c
