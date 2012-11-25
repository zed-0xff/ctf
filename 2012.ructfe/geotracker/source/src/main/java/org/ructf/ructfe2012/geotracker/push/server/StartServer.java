package org.ructf.ructfe2012.geotracker.push.server;


import org.apache.log4j.Logger;
import org.springframework.context.ApplicationContext;
import org.springframework.context.support.FileSystemXmlApplicationContext;

/**
 * User: iip
 * Date: 20.03.12
 * Time: 15:33
 */
public class StartServer {

	private final static Logger logger = Logger
			.getLogger(StartServer.class);
	
	public static void main(String[] args) throws Exception {
		if (args.length < 1) {
			logger.error("Required 1 argument: NAME of xml file without extension");
			System.exit(1);
		}
		try {
			ApplicationContext ctx = new FileSystemXmlApplicationContext(args[0] + ".xml");
			for (IStartable bean : ctx.getBeansOfType(IStartable.class).values()) {
				bean.start();
			}
			while(true) {
				Thread.sleep(1000);
			}
		} catch(Exception e) {
			logger.error("Init failed", e);
			System.exit(1);
		}
	}
}
