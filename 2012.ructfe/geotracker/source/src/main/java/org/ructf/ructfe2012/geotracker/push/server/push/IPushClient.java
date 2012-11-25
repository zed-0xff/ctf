package org.ructf.ructfe2012.geotracker.push.server.push;

import org.ructf.ructfe2012.geotracker.push.server.IClient;
import org.ructf.ructfe2012.geotracker.push.server.IServiceRequest;

public interface IPushClient extends IClient {

	void setServiceRequest(IServiceRequest serviceRequest);

}
