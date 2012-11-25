package org.ructf.ructfe2012.geotracker.push.server;

public interface IServiceRequest {

	boolean performRequest(IClient client, String data);
	
}
