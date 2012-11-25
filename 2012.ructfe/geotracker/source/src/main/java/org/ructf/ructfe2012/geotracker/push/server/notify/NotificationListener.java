package org.ructf.ructfe2012.geotracker.push.server.notify;

import java.util.Date;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;

import org.apache.log4j.Logger;
import org.ructf.ructfe2012.geotracker.push.server.Constants;
import org.ructf.ructfe2012.geotracker.push.server.IClient;
import org.ructf.ructfe2012.geotracker.push.server.IClientList;
import org.ructf.ructfe2012.geotracker.push.server.IKeepAliveReader;
import org.ructf.ructfe2012.geotracker.push.server.INotifiable;
import org.ructf.ructfe2012.geotracker.push.server.IPushable;
import org.ructf.ructfe2012.geotracker.push.server.Listener;
import org.springframework.util.StringUtils;


public class NotificationListener extends Listener implements INotifiable, IClientList, IKeepAliveReader {
	
	private final static Logger logger = Logger.getLogger(NotificationListener.class);
	
	private long keepAliveTimeout;
	
	public void setKeepAliveTimeout(long keepAliveTimeout) {
		this.keepAliveTimeout = keepAliveTimeout;
	}
	
	private INotificationRepository repository;
	
	public void setNotificationRepository(INotificationRepository repository) {
		this.repository = repository;
	}
	
	private Map<IClient, Date> clientTimeouts = new HashMap<IClient, Date>();
	
	@Override
	protected void fillClient(IClient client) {
		super.fillClient(client);
		((INotificationClient)client).setKeepAliveReader(this);
		synchronized (clientTimeouts) {
			clientTimeouts.put(client, new Date());
		}
	}
	
	public void notification(String serviceId, String clientId, String payload) {
		sendNotification(serviceId, clientId, repository.saveNotification(serviceId, clientId, payload));
	}
	private void sendNotification(String serviceId, String clientId, Notification n) {
		logger.info("Check notifications for " + clientId);
		synchronized (clients) {
			for (IClient c : clients) {
				if (c.identifyClient() != null && c.identifyClient().equals(clientId)) {
					if (c instanceof IPushable) {
						if (n.payload != null) {
							logger.info("Notification: " + n.payload);
							((IPushable)c).push(n.id + Constants.PUSH_STRING_PAYLOAD, n.payload);
						} else {
							logger.info("Notification empty");
							((IPushable)c).push(n.id + Constants.PUSH_STRING, null);
						}
					}
				}
			}
		}
	}

	@Override
	public void checkClients() {
		synchronized (clientTimeouts) {
			List<IClient> toDelete = new LinkedList<IClient>();
			for (Entry<IClient, Date> e : clientTimeouts.entrySet()) {
				if (new Date().getTime() - e.getValue().getTime() > keepAliveTimeout) {
					toDelete.add(e.getKey());
				}
			}
			for (IClient c : toDelete) {
				clientTimeouts.remove(c);
				c.close();
			}
		}
	}

	@Override
	public void readClient(INotificationClient client, String message) {
		synchronized (clientTimeouts) {
			clientTimeouts.put(client, new Date());
		}
		logger.info("Message " + message);
		String[] parts = message.split(":", 3);
		client.setClientId(parts[0]);
		List<Notification> res = repository.getMissedNotifications(parts[2], parts[0], Long.parseLong(parts[1]));
		for (Notification n : res) {
			sendNotification(parts[2], parts[0], n);
		}
		if (res.size() < 1) {
			logger.info("No notifications");
			client.send("OK\n");
		}
	}

	@Override
	public String getClients(String serviceId) {
		List<String> res = repository.getClients(serviceId);
		if (res.size() < 1) {
			return "empty";
		}
		return StringUtils.collectionToCommaDelimitedString(res);
	}

}
