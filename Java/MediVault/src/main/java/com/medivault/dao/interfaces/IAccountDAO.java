package com.medivault.dao.interfaces;

import com.medivault.entity.Account;
import java.util.List;

public interface IAccountDAO {
    Account findByUsername(String username);
    Account findById(int id);
    List<Account> findAll();
    boolean insert(Account a);
    boolean updateLastLogin(int accountId);
    boolean toggleActive(int accountId);
    boolean resetPassword(int accountId, String newHash);
    boolean isEmailTaken(String email, int excludeId);
    boolean update(Account a);
    boolean isUsernameTaken(String username);
}