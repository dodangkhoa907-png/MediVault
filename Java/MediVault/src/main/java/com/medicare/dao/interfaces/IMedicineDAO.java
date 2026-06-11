package com.medicare.dao.interfaces;

import com.medicare.entity.Medicines;
import java.util.List;

public interface IMedicineDAO {
    List<Medicines> findAll();
    List<Medicines> findAllIncludeInactive();   // kể cả đã ẩn
    Medicines findById(int id);
    Medicines findByBarcode(String barcode);
    List<Medicines> search(String keyword);
    List<Medicines> findLowStock();
    int countAll();
    int countLowStock();
    boolean insert(Medicines m);
    boolean update(Medicines m);
    boolean delete(int id);
    boolean toggleStatus(int id);
}