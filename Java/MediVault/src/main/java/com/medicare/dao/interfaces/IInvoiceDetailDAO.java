package com.medicare.dao.interfaces;

import com.medicare.entity.InvoiceDetail;
import java.util.List;

public interface IInvoiceDetailDAO {
    List<InvoiceDetail> findByInvoice(int invoiceId);
    boolean insert(InvoiceDetail d);
    boolean insertList(List<InvoiceDetail> details);
}