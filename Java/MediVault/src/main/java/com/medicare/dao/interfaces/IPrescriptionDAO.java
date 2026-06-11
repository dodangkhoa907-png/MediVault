package com.medicare.dao.interfaces;

import com.medicare.entity.Prescription;
import java.util.List;

public interface IPrescriptionDAO {
    boolean insert(Prescription p);
    Prescription findById(int id);
    List<Prescription> findByCustomer(int customerId);
}