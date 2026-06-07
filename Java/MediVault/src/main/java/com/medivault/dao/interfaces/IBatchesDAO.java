package com.medivault.dao.interfaces;

import com.medivault.entity.Batches;
import java.util.List;

public interface IBatchesDAO {
    List<Batches> findAll();
    List<Batches> findByMedicine(int medicineId);
    List<Batches> findExpiringSoon();
    List<Batches> findExpired();
    boolean insert(Batches b);
    int getTotalQuantity(int medicineId);
    Batches findNearestExpiry(int medicineId);
}