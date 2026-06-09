package com.medivault.dao.interfaces;

import com.medivault.entity.Batches;
import java.util.List;

public interface IBatchesDAO {
    List<Batches> findAll();
    List<Batches> findByMedicine(int medicineId);
    List<Batches> findAllByMedicine(int medicineId);   // kể cả hết hàng
    List<Batches> findExpiringSoon();
    List<Batches> findExpired();
    boolean insert(Batches b);
    boolean update(Batches b);
    boolean delete(int batchId);
    Batches findById(int batchId);
    int getTotalQuantity(int medicineId);
    int countByMedicine(int medicineId);
    Batches findNearestExpiry(int medicineId);

}