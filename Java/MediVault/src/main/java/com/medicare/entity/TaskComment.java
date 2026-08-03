package com.medicare.entity;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

public class TaskComment {
    private int taskCommentId;
    private int taskId;
    private int accountId;
    private String accountName; // JOIN Accounts.FullName
    private String body;
    private LocalDateTime createdAt;

    private static final DateTimeFormatter DTF = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");
    public String getCreatedAtDisplay() { return createdAt == null ? "" : createdAt.format(DTF); }

    public int getTaskCommentId()              { return taskCommentId; }
    public void setTaskCommentId(int v)        { this.taskCommentId = v; }
    public int getTaskId()                     { return taskId; }
    public void setTaskId(int v)               { this.taskId = v; }
    public int getAccountId()                  { return accountId; }
    public void setAccountId(int v)            { this.accountId = v; }
    public String getAccountName()             { return accountName; }
    public void setAccountName(String v)       { this.accountName = v; }
    public String getBody()                    { return body; }
    public void setBody(String v)              { this.body = v; }
    public LocalDateTime getCreatedAt()        { return createdAt; }
    public void setCreatedAt(LocalDateTime v)  { this.createdAt = v; }
}
