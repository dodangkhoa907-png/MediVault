package com.medicare.dao.interfaces;

import com.medicare.entity.Batches;
import java.util.List;
import java.util.Map;

public interface IBatchesDAO {
    List<Batches> findAll();
    List<Batches> findByMedicine(int medicineId);
    List<Batches> findAllByMedicine(int medicineId);   // kể cả hết hàng
    List<Batches> findExpiringSoon();
    List<Batches> findExpired();
    List<Batches> findByPO(int poId);   // các lô thuộc 1 đơn đặt hàng
    boolean insert(Batches b);
    boolean update(Batches b);
    boolean delete(int batchId);
    Batches findById(int batchId);
    int getTotalQuantity(int medicineId);
    Map<Integer, Integer> getTotalQuantityMap(); // all medicines in 1 query
    int countByMedicine(int medicineId);
    Batches findNearestExpiry(int medicineId);
}