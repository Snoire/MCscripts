.PHONY : install clean

install :
ifneq ($(MCPATH),)
	@echo "MCPATH=$(MCPATH)"
	-mkdir $(MCPATH)/logs
	-mkdir $(MCPATH)/worlds.backup
	sudo cp -u minecraft.zsh /usr/local/bin/mc
	sudo cp -u dav.sh /usr/local/bin/dav
	crontab -l | cat - mc.cron | crontab -
else
	@echo "usage: make install MCPATH=\"/path/minecraft\""
endif

clean :
	rm -rf inotify *.o *.bak
