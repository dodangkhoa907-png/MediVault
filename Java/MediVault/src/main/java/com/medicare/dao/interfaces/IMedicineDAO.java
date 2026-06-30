package com.medicare.dao.interfaces;

import com.medicare.entity.Medicines;
import java.util.List;

public interface IMedicineDAO {
    List<Medicines> findAll();
    List<Medicines> findAllIncludeInactive();
    List<Medicines> findAllWithStock();       // findAll + stock in 1 query
    Medicines findById(int id);
    Medicines findByBarcode(String barcode);
    List<Medicines> search(String keyword);
    List<Medicines> searchWithStock(String keyword); // search + stock in 1 query
    List<Medicines> findLowStock();
    int countAll();
    int countLowStock();
    List<Medicines> findPaged(String keyword, Integer catId, int page, int pageSize);
    int countForList(String keyword, Integer catId);
    boolean insert(Medicines m);
    int insertGetId(Medicines m);   // insert và trả về MedicineID mới — dùng khi cần tạo lô ban đầu
    boolean update(Medicines m);
    boolean updateImageUrl(int medicineId, String imageUrl);
    boolean delete(int id);
    boolean toggleStatus(int id);
}