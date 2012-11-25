package org.ructf.ructfe2012.geotracker.push.server;

import java.net.ServerSocket;
import java.net.Socket;
import java.util.LinkedList;
import java.util.List;

import org.apache.log4j.Logger;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.ApplicationContext;
import org.springframework.core.task.TaskRejectedException;
import org.springframework.scheduling.annotation.Async;

public abstract class Listener implements IListener {

	private final static Logger logger = Logger.getLogger(Listener.class);

	private int port;
	
	private Class<IClient> sampleClient;

	public void setPort(int port) {
		this.port = port;
	}

	public void setSampleClient(Class<IClient> sampleClient) {
		this.sampleClient = sampleClient;
	}

	@Autowired
	private ApplicationContext ctx;
	
	protected List<IClient> clients = new LinkedList<IClient>();
	
	protected void fillClient(IClient client) {
	}

	@Async
	public void start() {
		try {
			ServerSocket welcomeSocket = new ServerSocket(port);
			logger.info("!!! Server started on port " + port);
			while (true) {
				logger.debug("Creating client " + sampleClient.getName() + "...");
				IClient c = ctx.getBean(sampleClient);
				logger.debug("Initializing client...");
				c.setListener(this);
				fillClient(c);
				logger.debug("Registering client...");
				synchronized (clients) {
					clients.add(c);
				}
				logger.debug("Accepting...");
				Socket cs = welcomeSocket.accept();
				logger.debug("Accepted");
				try {
					c.serve(cs);
				} catch(TaskRejectedException _) {
					logger.warn("Rejected");
					cs.close();
				}
			}
		} catch (Exception e) {
			logger.error("Listener failed", e);
		}
		logger.info("!!! Server stopped on port " + port);
	}

	public void remove(IClient client) {
		synchronized (clients) {
			clients.remove(client);
		}
	}

}
