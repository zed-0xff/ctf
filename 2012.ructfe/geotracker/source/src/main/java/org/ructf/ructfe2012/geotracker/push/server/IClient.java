package org.ructf.ructfe2012.geotracker.push.server;

import java.net.Socket;

import org.springframework.scheduling.annotation.Async;

public interface IClient {
	
	String identifyClient();
	
	void setListener(IListener listener);

	@Async
	void serve(Socket socket);
	
	void send(String message);
	
	void close();
	
}
