package com.medicare.dao.interfaces;

import com.medicare.entity.Supplier;
import java.util.List;

public interface ISupplierDAO {
    List<Supplier> findAll();
    List<Supplier> findAllActive();
    Supplier findById(int id);
    boolean insert(Supplier s);
    boolean update(Supplier s);
    boolean toggleActive(int id);
}