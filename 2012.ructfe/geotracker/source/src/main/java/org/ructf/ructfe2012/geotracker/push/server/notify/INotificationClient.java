package org.ructf.ructfe2012.geotracker.push.server.notify;

import org.ructf.ructfe2012.geotracker.push.server.IClient;
import org.ructf.ructfe2012.geotracker.push.server.IKeepAliveReader;

public interface INotificationClient extends IClient {

	void setKeepAliveReader(IKeepAliveReader keepAliveReader);
	void setClientId(String clientId);

}
