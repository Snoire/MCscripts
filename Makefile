all : inotify
.PHONY : all install clean

install : inotify
	sudo mv inotify /usr/local/bin
	sudo cp minecraft /usr/local/bin/mc
	sudo cp dav.sh /usr/local/bin/dav

clean :
	rm -rf inotify *.o *.bak
