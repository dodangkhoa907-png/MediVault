package com.medicare.dao.interfaces;

import com.medicare.entity.Manufacturer;
import java.util.List;

public interface IManufacturerDAO {
    List<Manufacturer> findAll();
    Manufacturer findById(int id);
    boolean insert(Manufacturer m);
    boolean update(Manufacturer m);
}