package com.medivault.dao.interfaces;

import com.medivault.entity.MachineCommand;
import java.util.List;

public interface IMachineCommandDAO {
    List<MachineCommand> findPending();
    boolean updateStatus(int commandId, String newStatus);
    boolean retryFailed(int commandId, String errorMessage);
    boolean insert(MachineCommand m);
}