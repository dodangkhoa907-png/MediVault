package com.medivault.dao.interfaces;

import com.medivault.entity.Supplier;
import java.util.List;

public interface ISupplierDAO {
    List<Supplier> findAll();
    List<Supplier> findAllActive();
    Supplier findById(int id);
    boolean insert(Supplier s);
    boolean update(Supplier s);
    boolean toggleActive(int id);
}