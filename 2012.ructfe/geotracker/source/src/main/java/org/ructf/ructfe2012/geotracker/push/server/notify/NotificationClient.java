package org.ructf.ructfe2012.geotracker.push.server.notify;

import java.io.IOException;

import org.apache.log4j.Logger;
import org.ructf.ructfe2012.geotracker.push.server.Client;
import org.ructf.ructfe2012.geotracker.push.server.IKeepAliveReader;
import org.ructf.ructfe2012.geotracker.push.server.IPushable;


public class NotificationClient extends Client implements INotificationClient, IPushable {

	private final static Logger logger = Logger.getLogger(NotificationClient.class);

	private IKeepAliveReader keepAliveReader;
	
	public void setKeepAliveReader(IKeepAliveReader keepAliveReader) {
		this.keepAliveReader = keepAliveReader;
	}

	private String clientId;
	
	public String identifyClient() {
		return clientId;
	}

	public void setClientId(String clientId) {
		this.clientId = clientId;
	}

	@Override
	public void push(String pushString, String payload) {
		if (outToClient != null && clientId != null) {
			try {
				logger.info("pushed to " + clientId + ": " + pushString + "" + payload);
				outToClient.writeBytes(pushString);
				if (payload != null) {
					byte[] pbytes = payload.getBytes();
					outToClient.writeInt(pbytes.length);
					outToClient.write(pbytes);
				}
				outToClient.writeBytes("\n");
				outToClient.flush();
			} catch (IOException e) {
				close();
				logger.error("Client failed to receive notification");
			}
		}
	}

	@Override
	protected boolean readData(String data) {
		if (data == null) {
			logger.info("No data");
			return false;
		}
		if (data.trim().length() > 0) {
			logger.info(data);
			keepAliveReader.readClient(this, data);
		} else {
			logger.warn("Client with empty request");
		}
		return true;
	}

}
