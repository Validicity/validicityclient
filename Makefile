PREFIX = /usr/local

all: validicityclient

validicityclient: bin/validicityclient.dart
	pub run pubspec_extract
	dart2native -o $@ $^

.PHONY: install
install: validicityclient
	mkdir -p $(DESTDIR)$(PREFIX)/bin
	cp $< $(DESTDIR)$(PREFIX)/bin/$<

.PHONY: uninstall
uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/validicityclient

.PHONY: clean
clean:
	rm -f validicityclient
	touch bin/validicityclient.dart
