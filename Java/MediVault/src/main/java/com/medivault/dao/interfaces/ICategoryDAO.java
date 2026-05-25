package com.medivault.dao.interfaces;

import com.medivault.entity.Category;
import java.util.List;

public interface ICategoryDAO {
    List<Category> findAll();
    Category findById(int id);
    boolean insert(Category c);
    boolean update(Category c);
    boolean delete(int id);
}