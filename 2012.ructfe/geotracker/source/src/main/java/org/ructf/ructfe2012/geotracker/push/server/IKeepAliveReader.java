package org.ructf.ructfe2012.geotracker.push.server;

import org.ructf.ructfe2012.geotracker.push.server.notify.INotificationClient;

public interface IKeepAliveReader {

	void readClient(INotificationClient client, String message);
	
}
