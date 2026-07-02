package com.medicare.dao.interfaces;

import com.medicare.entity.PosStation;
import java.util.List;

public interface IPosStationDAO {
    List<PosStation> findAll();
    List<PosStation> findAllActive();
    PosStation findById(int id);
    boolean insert(PosStation pos);
    boolean update(PosStation pos);
    boolean delete(int id);
}
