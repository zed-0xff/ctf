package org.ructf.ructfe2012.geotracker.push.server;

public interface INotifiable {

	void notification(String serviceId, String clientId, String payload);

}
