package org.ructf.ructfe2012.geotracker.push.server.notify;

import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;

import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.persistence.Query;

import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

@Transactional
@Component
public class NotificationRepository implements INotificationRepository {

	@PersistenceContext
	EntityManager em;
	
	@Override
	public Notification saveNotification(String serviceId, String clientId, String payload) {
		synchronized(this) {
			payload = payload.replaceAll("[\r\n\0]", "");
			Notification n = new Notification();
			n.clientId = clientId;
			n.serviceId = serviceId;
			n.payload = payload;
			em.persist(n);
			return n;
		}
	}

	@SuppressWarnings("unchecked")
	@Override
	public List<Notification> getMissedNotifications(String serviceId, String clientId,
			Long lastId) {
		synchronized(this) {
			Map<String, String> conds = new HashMap<String, String>();
			Map<String, Object> params = new HashMap<String, Object>();
			if (clientId != null && clientId.length() > 0) { params.put("clientId", clientId); conds.put("clientId", "="); }
			params.put("id", (lastId == null ? 0 : lastId)); conds.put("id", ">");
			Query q = buildQuery(conds, params);
			return q.getResultList();
		}
	}

	@SuppressWarnings("unchecked")
	@Override
	public List<String> getClients(String serviceId) {
		synchronized(this) {
			Map<String, String> conds = new HashMap<String, String>();
			Map<String, Object> params = new HashMap<String, Object>();
			if (serviceId != null && serviceId.length() > 0) { params.put("serviceId", serviceId); conds.put("serviceId", "="); }
			Query q = buildQuery(conds, params);
			List<String> res = new LinkedList<String>();
			for (Notification n : (List<Notification>)q.getResultList()) {
				res.add(n.serviceId + "|" + n.clientId);
			}
			return res;
		}
	}

	private Query buildQuery(Map<String, String> conds, Map<String, Object> params) {
		String sql = "select o from Notification o";
		for (String key : params.keySet()) {
			if (sql.contains("where")) {
				sql += " and ";
			} else {
				sql += " where ";
			}
			sql += key + " " + conds.get(key) + " :" + key;
		}
		Query q = em.createQuery(sql);
		for (Entry<String, Object> e : params.entrySet()) {
			q.setParameter(e.getKey(), e.getValue());
		}
		return q;
	}
	
}
