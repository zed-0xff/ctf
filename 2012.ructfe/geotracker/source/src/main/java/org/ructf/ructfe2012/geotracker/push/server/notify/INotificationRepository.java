package org.ructf.ructfe2012.geotracker.push.server.notify;

import java.util.List;

public interface INotificationRepository {

	Notification saveNotification(String serviceId, String clientId, String payload);
	List<Notification> getMissedNotifications(String serviceId, String clientId, Long lastId);
	List<String> getClients(String serviceId);
	
}
