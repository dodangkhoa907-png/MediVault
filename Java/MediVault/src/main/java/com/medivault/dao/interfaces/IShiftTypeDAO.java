package com.medivault.dao.interfaces;

import com.medivault.entity.ShiftType;
import java.util.List;

public interface IShiftTypeDAO {
    List<ShiftType> findAll();
    List<ShiftType> findAllActive();
    ShiftType findById(int shiftTypeId);
    boolean insert(ShiftType st);
    boolean update(ShiftType st);
    boolean setActive(int shiftTypeId, boolean active);
}
