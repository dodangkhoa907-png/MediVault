package com.medicare.controller.admin;

import com.medicare.dao.AccountDAO;
import com.medicare.dao.InvoiceDAO;
import com.medicare.dao.ShiftDAO;
import com.medicare.dao.interfaces.IAccountDAO;
import com.medicare.dao.interfaces.IInvoiceDAO;
import com.medicare.dao.interfaces.IShiftDAO;
import com.medicare.entity.Account;
import com.medicare.entity.Shift;
import com.medicare.util.SidebarHelper;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.*;

/**
 * ReportServlet — Báo cáo doanh thu tổng quan cho Admin.
 * URL: /reports
 *
 * Đây là nơi tiếp nhận toàn bộ phần "💰 Doanh thu" đã được chuyển từ
 * shift-list.jsp (tab Doanh thu) sang, đồng thời bổ sung các chỉ số quản trị
 * tài chính thật sự: lợi nhuận gộp, giảm giá, hàng trả lại, doanh thu theo
 * Hãng sản xuất / Nhóm thuốc, và doanh thu theo khung giờ (peak hours).
 *
 * GET ?action=          → showOverview  (trang chính, SSR theo tháng/năm)
 * GET ?action=chart-data → JSON cho tất cả biểu đồ (gọi lại khi đổi tháng/năm)
 */
@WebServlet("/reports")
public class ReportServlet extends HttpServlet {

    private final IInvoiceDAO invoiceDAO = new InvoiceDAO();
    private final IShiftDAO   shiftDAO   = new ShiftDAO();
    private final IAccountDAO accountDAO = new AccountDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        Account adminAcc = session != null ? (Account) session.getAttribute("adminAccount") : null;
        if (adminAcc == null || adminAcc.getRoleId() != 1) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }

        String action = req.getParameter("action");
        if ("chart-data".equals(action)) {
            handleChartData(req, resp);
        } else {
            showOverview(req, resp);
        }
    }

    // ── OVERVIEW (SSR) ──────────────────────────────────────────────────────
    private void showOverview(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        int month = parseIntOr(req.getParameter("month"), LocalDate.now().getMonthValue());
        int year  = parseIntOr(req.getParameter("year"),  LocalDate.now().getYear());
        LocalDate from = LocalDate.of(year, month, 1);
        LocalDate to   = from.withDayOfMonth(from.lengthOfMonth());

        // ── Chỉ số tài chính ──────────────────────────────────────────────
        BigDecimal grossRevenue = invoiceDAO.sumGrossRevenueByDateRange(from, to);   // trước giảm giá
        BigDecimal discount     = invoiceDAO.sumDiscountByDateRange(from, to);
        BigDecimal refund       = invoiceDAO.sumRefundByDateRange(from, to);
        BigDecimal cogs         = invoiceDAO.sumCOGSByDateRange(from, to);
        BigDecimal netRevenue   = grossRevenue.subtract(discount).subtract(refund);   // doanh thu thuần
        BigDecimal grossProfit  = netRevenue.subtract(cogs);                          // lợi nhuận gộp
        int invoiceCount        = invoiceDAO.countInvoicesByDateRange(from, to);

        req.setAttribute("grossRevenue", grossRevenue);
        req.setAttribute("discount",     discount);
        req.setAttribute("refund",       refund);
        req.setAttribute("cogs",         cogs);
        req.setAttribute("netRevenue",   netRevenue);
        req.setAttribute("grossProfit",  grossProfit);
        req.setAttribute("invoiceCount", invoiceCount);

        // ── So với tháng trước (trend badge trên KPI) ──────────────────────
        LocalDate prevFrom = from.minusMonths(1).withDayOfMonth(1);
        LocalDate prevTo   = prevFrom.withDayOfMonth(prevFrom.lengthOfMonth());
        BigDecimal prevGrossRevenue = invoiceDAO.sumGrossRevenueByDateRange(prevFrom, prevTo);
        BigDecimal prevDiscount     = invoiceDAO.sumDiscountByDateRange(prevFrom, prevTo);
        BigDecimal prevRefund       = invoiceDAO.sumRefundByDateRange(prevFrom, prevTo);
        BigDecimal prevCogs         = invoiceDAO.sumCOGSByDateRange(prevFrom, prevTo);
        BigDecimal prevNetRevenue   = prevGrossRevenue.subtract(prevDiscount).subtract(prevRefund);
        BigDecimal prevGrossProfit  = prevNetRevenue.subtract(prevCogs);
        req.setAttribute("netRevenuePct",  percentChange(prevNetRevenue, netRevenue));
        req.setAttribute("grossProfitPct", percentChange(prevGrossProfit, grossProfit));
        req.setAttribute("cogsPct",        percentChange(prevCogs, cogs));

        // % giảm trừ trên doanh thu gộp — tính sẵn ở Java để tránh chia BigDecimal trong EL
        BigDecimal deductSum = discount.add(refund);
        Double deductPct = grossRevenue.compareTo(BigDecimal.ZERO) == 0 ? null :
                deductSum.divide(grossRevenue, 4, java.math.RoundingMode.HALF_UP)
                .multiply(BigDecimal.valueOf(100)).doubleValue();
        req.setAttribute("deductPct", deductPct);

        // ── Đối soát quỹ ca (chuyển nguyên từ shift-list.jsp tab Doanh thu) ──
        List<Shift> monthShifts = shiftDAO.findByDateRange(from, to);
        Map<Integer, Account> accountMap = new HashMap<>();
        for (Shift s : monthShifts) {
            if (!accountMap.containsKey(s.getAccountId())) {
                Account a = accountDAO.findById(s.getAccountId());
                if (a != null) accountMap.put(s.getAccountId(), a);
            }
        }
        req.setAttribute("monthShifts", monthShifts);
        req.setAttribute("accountMap",  accountMap);

        req.setAttribute("repMonth", month);
        req.setAttribute("repYear",  year);

        SidebarHelper.load(req);

        req.getRequestDispatcher("/WEB-INF/views/admin/report-list.jsp").forward(req, resp);
    }

    // ── CHART DATA (AJAX, JSON) ──────────────────────────────────────────────
    private void handleChartData(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        int month = parseIntOr(req.getParameter("month"), LocalDate.now().getMonthValue());
        int year  = parseIntOr(req.getParameter("year"),  LocalDate.now().getYear());
        LocalDate from = LocalDate.of(year, month, 1);
        LocalDate to   = from.withDayOfMonth(from.lengthOfMonth());

        StringBuilder json = new StringBuilder("{");

        // 1) Đối soát quỹ ca — tiền đầu/cuối ca theo ngày (logic cũ, chuyển từ ShiftServlet)
        List<Shift> shifts = shiftDAO.findByDateRange(from, to);
        TreeMap<String, long[]> dailyCash = new TreeMap<>();
        for (Shift s : shifts) {
            if (s.getStartTime() == null) continue;
            String dayKey = s.getStartTime().toLocalDate().toString();
            dailyCash.putIfAbsent(dayKey, new long[]{0, 0});
            if (s.getOpeningCash() != null) dailyCash.get(dayKey)[0] += s.getOpeningCash().longValue();
            if (s.getClosingCash() != null) dailyCash.get(dayKey)[1] += s.getClosingCash().longValue();
        }
        List<String> cashLabels = new ArrayList<>();
        List<Long> cashOpening  = new ArrayList<>();
        List<Long> cashClosing  = new ArrayList<>();
        for (Map.Entry<String, long[]> e : dailyCash.entrySet()) {
            cashLabels.add(e.getKey().substring(8) + "/" + month);
            cashOpening.add(e.getValue()[0]);
            cashClosing.add(e.getValue()[1]);
        }
        json.append("\"cashLabels\":").append(jsonStrArray(cashLabels)).append(",");
        json.append("\"cashOpening\":").append(jsonNumArray(cashOpening)).append(",");
        json.append("\"cashClosing\":").append(jsonNumArray(cashClosing)).append(",");

        // 2) Doanh thu — Giá vốn — Lợi nhuận gộp theo ngày (Grouped Column Chart, theo khuyến nghị #1)
        TreeMap<String, BigDecimal[]> dailyFin = invoiceDAO.dailyFinanceByDateRange(from, to);
        List<String> finLabels  = new ArrayList<>();
        List<BigDecimal> finRev = new ArrayList<>();
        List<BigDecimal> finCogs = new ArrayList<>();
        List<BigDecimal> finProfit = new ArrayList<>();
        for (Map.Entry<String, BigDecimal[]> e : dailyFin.entrySet()) {
            finLabels.add(e.getKey().substring(8) + "/" + month);
            BigDecimal rev = e.getValue()[0], cg = e.getValue()[1];
            finRev.add(rev);
            finCogs.add(cg);
            finProfit.add(rev.subtract(cg));
        }
        json.append("\"finLabels\":").append(jsonStrArray(finLabels)).append(",");
        json.append("\"finRevenue\":").append(jsonNumArray(finRev)).append(",");
        json.append("\"finCogs\":").append(jsonNumArray(finCogs)).append(",");
        json.append("\"finProfit\":").append(jsonNumArray(finProfit)).append(",");

        // 2b) Số liệu cho Waterfall Chart (Doanh thu gộp → Giảm giá → Trả hàng → Doanh thu thuần)
        BigDecimal wfGross    = invoiceDAO.sumGrossRevenueByDateRange(from, to);
        BigDecimal wfDiscount = invoiceDAO.sumDiscountByDateRange(from, to);
        BigDecimal wfRefund   = invoiceDAO.sumRefundByDateRange(from, to);
        BigDecimal wfNet      = wfGross.subtract(wfDiscount).subtract(wfRefund);
        json.append("\"wfGross\":").append(wfGross).append(",");
        json.append("\"wfDiscount\":").append(wfDiscount).append(",");
        json.append("\"wfRefund\":").append(wfRefund).append(",");
        json.append("\"wfNet\":").append(wfNet).append(",");

        // 3) Doanh thu theo Hãng sản xuất (top 7 + "Khác")
        LinkedHashMap<String, BigDecimal> mfg = invoiceDAO.revenueByManufacturer(from, to);
        appendGroupedJson(json, "mfg", mfg);

        // 4) Doanh thu theo Nhóm thuốc (top 7 + "Khác")
        LinkedHashMap<String, BigDecimal> cat = invoiceDAO.revenueByCategory(from, to);
        appendGroupedJson(json, "cat", cat);

        // 5) Doanh thu theo khung giờ (0h → 23h, giờ VN)
        TreeMap<Integer, BigDecimal> hourly = invoiceDAO.revenueByHour(from, to);
        List<String> hourLabels = new ArrayList<>();
        List<BigDecimal> hourValues = new ArrayList<>();
        for (Map.Entry<Integer, BigDecimal> e : hourly.entrySet()) {
            hourLabels.add(String.format("%02dh", e.getKey()));
            hourValues.add(e.getValue());
        }
        json.append("\"hourLabels\":").append(jsonStrArray(hourLabels)).append(",");
        json.append("\"hourValues\":").append(jsonNumArray(hourValues));

        json.append("}");

        resp.setContentType("application/json;charset=UTF-8");
        resp.getWriter().print(json);
    }

    /** Gộp group nhỏ thành "Khác" nếu có nhiều hơn 7 nhóm, rồi append vào JSON builder. */
    private void appendGroupedJson(StringBuilder json, String prefix, LinkedHashMap<String, BigDecimal> data) {
        List<String> labels = new ArrayList<>();
        List<BigDecimal> values = new ArrayList<>();
        int i = 0;
        BigDecimal otherSum = BigDecimal.ZERO;
        for (Map.Entry<String, BigDecimal> e : data.entrySet()) {
            if (i < 7) {
                labels.add(e.getKey());
                values.add(e.getValue());
            } else {
                otherSum = otherSum.add(e.getValue());
            }
            i++;
        }
        if (otherSum.compareTo(BigDecimal.ZERO) > 0) {
            labels.add("Khác");
            values.add(otherSum);
        }
        json.append("\"").append(prefix).append("Labels\":").append(jsonStrArray(labels)).append(",");
        json.append("\"").append(prefix).append("Values\":").append(jsonNumArray(values)).append(",");
    }

    // ── JSON helpers (build thủ công — tránh dependency ngoài, đồng nhất style ShiftServlet) ──
    private String jsonStrArray(List<String> items) {
        StringBuilder sb = new StringBuilder("[");
        for (int i = 0; i < items.size(); i++) {
            if (i > 0) sb.append(",");
            sb.append("\"").append(escapeJson(items.get(i))).append("\"");
        }
        return sb.append("]").toString();
    }

    private String jsonNumArray(List<? extends Number> items) {
        StringBuilder sb = new StringBuilder("[");
        for (int i = 0; i < items.size(); i++) {
            if (i > 0) sb.append(",");
            Number n = items.get(i) != null ? items.get(i) : 0;
            sb.append(n.toString());
        }
        return sb.append("]").toString();
    }

    private String escapeJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"");
    }

    /** % thay đổi so với kỳ trước. Trả về null nếu kỳ trước = 0 (không có cơ sở so sánh). */
    private Double percentChange(BigDecimal prev, BigDecimal current) {
        if (prev == null || prev.compareTo(BigDecimal.ZERO) == 0) return null;
        return current.subtract(prev)
                .divide(prev, 4, java.math.RoundingMode.HALF_UP)
                .multiply(BigDecimal.valueOf(100))
                .doubleValue();
    }

    private int parseIntOr(String s, int def) {
        if (s == null || s.isEmpty()) return def;
        try { return Integer.parseInt(s); } catch (NumberFormatException e) { return def; }
    }
}