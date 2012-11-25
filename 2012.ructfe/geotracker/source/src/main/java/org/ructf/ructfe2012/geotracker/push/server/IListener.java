package org.ructf.ructfe2012.geotracker.push.server;


public interface IListener extends IStartable {
	
	void remove(IClient client);

}
