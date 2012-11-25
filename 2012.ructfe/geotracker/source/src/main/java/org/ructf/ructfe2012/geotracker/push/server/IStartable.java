package org.ructf.ructfe2012.geotracker.push.server;

import org.springframework.scheduling.annotation.Async;

public interface IStartable {

	@Async
	void start();

}
