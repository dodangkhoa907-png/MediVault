package com.medivault.dao.interfaces;

import com.medivault.entity.StaffAuditLog;
import java.util.List;

public interface IStaffAuditLogDAO {
    boolean log(StaffAuditLog log);
    List<StaffAuditLog> findRecentByAccount(int accountId, int limit);
}