package org.ructf.ructfe2012.geotracker.push.server.push;

import org.ructf.ructfe2012.geotracker.push.server.Client;
import org.ructf.ructfe2012.geotracker.push.server.IServiceRequest;

public class PushClient extends Client implements IPushClient {
	
	private IServiceRequest serviceRequest;
	
	public void setServiceRequest(IServiceRequest serviceRequest) {
		this.serviceRequest = serviceRequest;
	}
	
	@Override
	protected boolean readData(String data) {
		return serviceRequest.performRequest(this, data);
	}

	@Override
	public String identifyClient() {
		return null;
	}

}
