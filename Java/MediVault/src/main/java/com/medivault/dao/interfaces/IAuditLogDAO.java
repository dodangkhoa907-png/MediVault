package com.medivault.dao.interfaces;

import com.medivault.entity.AuditLog;
import java.util.List;

public interface IAuditLogDAO {
    boolean insert(AuditLog log);
    List<AuditLog> findPaginated(int page, int pageSize, String keyword);
    int countAll(String keyword);
}