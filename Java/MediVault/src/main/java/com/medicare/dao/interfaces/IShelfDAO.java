package com.medicare.dao.interfaces;

import com.medicare.entity.Shelf;
import java.util.List;

public interface IShelfDAO {
    List<Shelf> findAll();
    Shelf findById(int id);
    Shelf findBySlotCode(String slotCode);
    boolean insert(Shelf s);
    boolean update(Shelf s);
}