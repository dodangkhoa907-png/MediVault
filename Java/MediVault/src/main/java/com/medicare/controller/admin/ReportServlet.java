package com.medicare.controller.admin;

import com.medicare.config.CacheManager;
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

    /** Gộp các chỉ số tài chính của 1 kỳ (from-to) để tính 1 lần, dùng chung cho SSR + chart-data. */
    private static final class FinKpi {
        final BigDecimal gross, discount, refund, cogs;
        final int invoiceCount;
        FinKpi(BigDecimal gross, BigDecimal discount, BigDecimal refund, BigDecimal cogs, int invoiceCount) {
            this.gross = gross; this.discount = discount; this.refund = refund;
            this.cogs = cogs; this.invoiceCount = invoiceCount;
        }
    }

    // ── Cache 15 phút — chuyển tab qua lại hoặc showOverview → chart-data gọi lại
    // cùng kỳ (from-to) sẽ không query DB lần 2. Dữ liệu chỉ đổi khi có hóa đơn mới,
    // trễ tối đa 15 phút là chấp nhận được cho trang báo cáo (không phải real-time POS).
    private FinKpi loadFinKpi(LocalDate from, LocalDate to) {
        String key = "report.kpi." + from + "_" + to;
        return CacheManager.get15(key, () -> new FinKpi(
                invoiceDAO.sumGrossRevenueByDateRange(from, to),
                invoiceDAO.sumDiscountByDateRange(from, to),
                invoiceDAO.sumRefundByDateRange(from, to),
                invoiceDAO.sumCOGSByDateRange(from, to),
                invoiceDAO.countInvoicesByDateRange(from, to)));
    }

    private List<Shift> loadShifts(LocalDate from, LocalDate to) {
        String key = "report.shifts." + from + "_" + to;
        return CacheManager.get15(key, () -> shiftDAO.findByDateRange(from, to));
    }

    private TreeMap<String, BigDecimal[]> loadDailyFinance(LocalDate from, LocalDate to) {
        String key = "report.dailyFin." + from + "_" + to;
        return CacheManager.get15(key, () -> invoiceDAO.dailyFinanceByDateRange(from, to));
    }

    private LinkedHashMap<String, BigDecimal> loadRevenueByManufacturer(LocalDate from, LocalDate to) {
        String key = "report.mfg." + from + "_" + to;
        return CacheManager.get15(key, () -> invoiceDAO.revenueByManufacturer(from, to));
    }

    private LinkedHashMap<String, BigDecimal> loadRevenueByCategory(LocalDate from, LocalDate to) {
        String key = "report.cat." + from + "_" + to;
        return CacheManager.get15(key, () -> invoiceDAO.revenueByCategory(from, to));
    }

    private TreeMap<Integer, BigDecimal> loadRevenueByHour(LocalDate from, LocalDate to) {
        String key = "report.hourly." + from + "_" + to;
        return CacheManager.get15(key, () -> invoiceDAO.revenueByHour(from, to));
    }

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

        // ── Chỉ số tài chính (cache 15 phút — dùng chung với handleChartData) ──
        FinKpi kpi = loadFinKpi(from, to);
        BigDecimal grossRevenue = kpi.gross;      // trước giảm giá
        BigDecimal discount     = kpi.discount;
        BigDecimal refund       = kpi.refund;
        BigDecimal cogs         = kpi.cogs;
        BigDecimal netRevenue   = grossRevenue.subtract(discount).subtract(refund);   // doanh thu thuần
        BigDecimal grossProfit  = netRevenue.subtract(cogs);                          // lợi nhuận gộp
        int invoiceCount        = kpi.invoiceCount;

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
        FinKpi prevKpi = loadFinKpi(prevFrom, prevTo);
        BigDecimal prevGrossRevenue = prevKpi.gross;
        BigDecimal prevDiscount     = prevKpi.discount;
        BigDecimal prevRefund       = prevKpi.refund;
        BigDecimal prevCogs         = prevKpi.cogs;
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
        List<Shift> monthShifts = loadShifts(from, to);
        Set<Integer> shiftAccountIds = new HashSet<>();
        for (Shift s : monthShifts) shiftAccountIds.add(s.getAccountId());
        Map<Integer, Account> accountMap = new HashMap<>();
        if (!shiftAccountIds.isEmpty()) {
            for (Account a : accountDAO.findAccountsByIds(new ArrayList<>(shiftAccountIds))) {
                accountMap.put(a.getAccountId(), a);
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
        // dùng chung cache với showOverview (cùng kỳ from-to) — tránh query trùng lặp.
        List<Shift> shifts = loadShifts(from, to);
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
        TreeMap<String, BigDecimal[]> dailyFin = loadDailyFinance(from, to);
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
        // dùng chung cache KPI với showOverview — tránh tính lại gross/discount/refund lần 2.
        FinKpi wfKpi = loadFinKpi(from, to);
        BigDecimal wfGross    = wfKpi.gross;
        BigDecimal wfDiscount = wfKpi.discount;
        BigDecimal wfRefund   = wfKpi.refund;
        BigDecimal wfNet      = wfGross.subtract(wfDiscount).subtract(wfRefund);
        json.append("\"wfGross\":").append(wfGross).append(",");
        json.append("\"wfDiscount\":").append(wfDiscount).append(",");
        json.append("\"wfRefund\":").append(wfRefund).append(",");
        json.append("\"wfNet\":").append(wfNet).append(",");

        // 3) Doanh thu theo Hãng sản xuất (top 7 + "Khác")
        LinkedHashMap<String, BigDecimal> mfg = loadRevenueByManufacturer(from, to);
        appendGroupedJson(json, "mfg", mfg);

        // 4) Doanh thu theo Nhóm thuốc (top 7 + "Khác")
        LinkedHashMap<String, BigDecimal> cat = loadRevenueByCategory(from, to);
        appendGroupedJson(json, "cat", cat);

        // 5) Doanh thu theo khung giờ (0h → 23h, giờ VN) — CẢ THÁNG đang chọn (cộng dồn tất cả
        // các ngày trong tháng vào cùng 1 khung giờ, phục vụ phân tích "giờ vàng" — KHÔNG phải
        // riêng hôm nay, dễ gây hiểu nhầm nên có thêm bản "hôm nay" riêng ngay bên dưới.
        TreeMap<Integer, BigDecimal> hourly = loadRevenueByHour(from, to);
        List<String> hourLabels = new ArrayList<>();
        List<BigDecimal> hourValues = new ArrayList<>();
        for (Map.Entry<Integer, BigDecimal> e : hourly.entrySet()) {
            hourLabels.add(String.format("%02dh", e.getKey()));
            hourValues.add(e.getValue());
        }
        json.append("\"hourLabels\":").append(jsonStrArray(hourLabels)).append(",");
        json.append("\"hourValues\":").append(jsonNumArray(hourValues)).append(",");

        // 5b) Doanh thu theo khung giờ — CHỈ RIÊNG HÔM NAY (ngày thực tế hiện tại, không phụ
        // thuộc tháng/năm đang xem trên bộ lọc) — phục vụ nút chuyển "Hôm nay" trên biểu đồ.
        LocalDate today = LocalDate.now();
        TreeMap<Integer, BigDecimal> hourlyToday = loadRevenueByHour(today, today);
        List<BigDecimal> hourTodayValues = new ArrayList<>();
        for (Map.Entry<Integer, BigDecimal> e : hourlyToday.entrySet()) {
            hourTodayValues.add(e.getValue());
        }
        json.append("\"hourTodayValues\":").append(jsonNumArray(hourTodayValues));

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