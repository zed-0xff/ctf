package org.ructf.ructfe2012.geotracker.push.server.notify;

import java.util.Date;

import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.Id;
import javax.persistence.PrePersist;

@Entity
public class Notification {

	@Id
	@GeneratedValue
	public Long id;
	public String clientId;
	public String serviceId;
	public String payload;
	public Date dateAdded;
	
	@PrePersist
	void setDateAdded() {
		dateAdded = new Date();
	}
	
}
