package com.medivault.dao.interfaces;

import com.medivault.entity.InvoiceDetail;
import java.util.List;

public interface IInvoiceDetailDAO {
    List<InvoiceDetail> findByInvoice(int invoiceId);
    boolean insert(InvoiceDetail d);
    boolean insertList(List<InvoiceDetail> details);
}