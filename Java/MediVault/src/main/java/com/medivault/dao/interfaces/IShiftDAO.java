package com.medivault.dao.interfaces;

import com.medivault.entity.Shift;
import java.math.BigDecimal;
import java.util.List;

public interface IShiftDAO {
    boolean openShift(int accountId, BigDecimal openingCash);
    boolean closeShift(int shiftId, BigDecimal closingCash, String notes);
    Shift findCurrent(int accountId);
    Shift findById(int id);
    List<Shift> findByAccount(int accountId);
}