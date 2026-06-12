package com.medicare.dao.interfaces;

import com.medicare.entity.StaffAuditLog;
import java.util.List;

public interface IStaffAuditLogDAO {
    boolean log(StaffAuditLog log);
    List<StaffAuditLog> findRecentByAccount(int accountId, int limit);
}