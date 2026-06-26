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
    boolean addStock(int batchId, int qty); // bổ sung hàng vào lô đã có
    boolean delete(int batchId);       // CANCELLED — chỉ khi chưa bán
    boolean destroyBatch(int batchId); // DESTROYED — hết hạn / hỏng hóc
    boolean hasSalesHistory(int batchId); // CurrentQuantity < InitialQuantity
    boolean existsBatchNumber(String batchNumber, int medicineId, int supplierId, int excludeBatchId);
    Batches findById(int batchId);
    Batches findByMedicineAndBatchNumber(int medicineId, String batchNumber);
    int getTotalQuantity(int medicineId);
    Map<Integer, Integer> getTotalQuantityMap(); // all medicines in 1 query
    int countByMedicine(int medicineId);
    Batches findNearestExpiry(int medicineId);

    /** 1 query tóm tắt lô cho trang medicine-list (hover card + tab badges) */
    void loadBatchSummary(
            Map<Integer, Integer> activeCountOut,
            Map<Integer, Integer> soonCountOut,
            Map<Integer, Integer> expiredCountOut,
            Map<Integer, String>  nearestExpiryOut);
}