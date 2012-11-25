package org.ructf.ructfe2012.geotracker.push.server.push;

import java.util.HashMap;
import java.util.Map;

import org.ructf.ructfe2012.geotracker.push.server.Constants;
import org.ructf.ructfe2012.geotracker.push.server.IClient;
import org.ructf.ructfe2012.geotracker.push.server.IClientList;
import org.ructf.ructfe2012.geotracker.push.server.INotifiable;
import org.ructf.ructfe2012.geotracker.push.server.IServiceRequest;
import org.ructf.ructfe2012.geotracker.push.server.Listener;

public class PushListener extends Listener implements IServiceRequest {

	@Override
	protected void fillClient(IClient client) {
		super.fillClient(client);
		((IPushClient)client).setServiceRequest(this);
	}

	private INotifiable notificationSender;
	
	public void setNotificationSender(INotifiable notificationSender) {
		this.notificationSender = notificationSender;
	}
	
	private IClientList clientList;

	public void setClientList(IClientList clientList) {
		this.clientList = clientList;
	}

	private interface ICommand {
		void run(String data);
	}
	
	private Map<String, ICommand> commands = new HashMap<String, ICommand>() {
		private static final long serialVersionUID = 1L;
		{
			put(Constants.REQUEST_PUSH, new ICommand() {
				@Override
				public void run(String data) {
					String[] command = data.split("\\|", 4);
					notificationSender.notification(command[0], command[2], command[3]);
				}
			});
		}
	};
	
	@Override
	public boolean performRequest(IClient client, String data) {
		String[] command = data.split("\\|");
		if (command.length > 1) {
			if (commands.containsKey(command[1])) {
				commands.get(command[1]).run(data);
			}
		}
			client.send(clientList.getClients(command[0]) + '\n');
		return false;
	}
	
}
