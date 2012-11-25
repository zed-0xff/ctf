package org.ructf.ructfe2012.geotracker.push.server;

import java.io.BufferedReader;
import java.io.DataOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.Socket;

import org.apache.log4j.Logger;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Async;

public abstract class Client implements IClient {

	private final static Logger logger = Logger.getLogger(Client.class);
	
	private IListener listener;
	
	public void setListener(IListener listener) {
		this.listener = listener;
	}

	@Autowired
	@Value("${client.timeout}")
	private int timeout;

	private Socket clientSocket;

	private BufferedReader inFromClient;
	
	protected DataOutputStream outToClient;
	
	private boolean active;
	
	protected abstract boolean readData(String data);
	
	@Async
	public void serve(Socket socket) {
		clientSocket = socket;
		try {
			logger.debug("Client connected");
			active = true;
			socket.setSoTimeout(timeout * 2);
			inFromClient = new BufferedReader(
					new InputStreamReader(socket.getInputStream()));
			outToClient = new DataOutputStream(
					socket.getOutputStream());
			logger.debug("Client streams opened");
			while(active) {
				if (!readData(inFromClient.readLine())) {
					break;
				}
			}
		} catch (Exception e) {
			logger.error("Client terminated", e);
		}
		close();
	}
	
	public void send(String message) {
		if (outToClient != null) {
			try {
				outToClient.writeBytes(message);
				outToClient.flush();
			} catch (IOException e) {
				close();
				logger.error("Client failed to receive message");
			}
		}
	}
	
	public void close() {
		logger.info("Client closed");
		active = false;
		listener.remove(this);
		try {
			if (outToClient != null) {
				outToClient.close();
			}
			outToClient = null;
			if (inFromClient != null) {
				inFromClient.close();
			}
			inFromClient = null;
			if (clientSocket != null) {
				clientSocket.close();
			}
			clientSocket = null;
		} catch (IOException _) {
			logger.warn("Client close error", _);
		}
	}
	
}
