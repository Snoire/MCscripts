all : inotify
.PHONY : all install clean

install : inotify
	sudo mv inotify /bin
	sudo cp minecraft /bin/mc
	sudo cp dav.sh /bin/dav

clean :
	rm -rf inotify *.o *.bak
