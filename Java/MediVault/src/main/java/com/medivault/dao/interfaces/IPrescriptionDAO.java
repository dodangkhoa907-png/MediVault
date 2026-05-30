package com.medivault.dao.interfaces;

import com.medivault.entity.Prescription;
import java.util.List;

public interface IPrescriptionDAO {
    boolean insert(Prescription p);
    Prescription findById(int id);
    List<Prescription> findByCustomer(int customerId);
}