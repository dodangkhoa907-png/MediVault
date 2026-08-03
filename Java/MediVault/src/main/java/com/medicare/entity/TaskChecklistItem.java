package com.medicare.entity;

import java.time.LocalDateTime;

public class TaskChecklistItem {
    private int checklistItemId;
    private int taskId;
    private String itemText;
    private boolean done;
    private int sortOrder;
    private LocalDateTime createdAt;

    public int getChecklistItemId()            { return checklistItemId; }
    public void setChecklistItemId(int v)      { this.checklistItemId = v; }
    public int getTaskId()                     { return taskId; }
    public void setTaskId(int v)               { this.taskId = v; }
    public String getItemText()                { return itemText; }
    public void setItemText(String v)          { this.itemText = v; }
    public boolean isDone()                    { return done; }
    public void setDone(boolean v)             { this.done = v; }
    public int getSortOrder()                  { return sortOrder; }
    public void setSortOrder(int v)            { this.sortOrder = v; }
    public LocalDateTime getCreatedAt()        { return createdAt; }
    public void setCreatedAt(LocalDateTime v)  { this.createdAt = v; }
}
