package com.medivault.dao.interfaces;

import com.medivault.entity.Customer;
import java.util.List;

public interface ICustomerDAO {
    List<Customer> findAll();
    Customer findById(int id);
    Customer findByPhone(String phone);
    boolean insert(Customer c);
    boolean update(Customer c);
}