geotracker:
	mvn install

install: geotracker
	cp target/server-1.0.jar /home/geotracker/geotracker.jar
	cp src/push-server.xml /home/geotracker/push-server.xml
	cp src/geotracker.sh /home/geotracker/geotracker.sh
	chmod 0775 /home/geotracker/geotracker.sh

uninstall:
	rm -rf /home/geotracker/*

clean:
	rm -rf target

all:
	geotracker
