<%@ page contentType="text/html;charset=UTF-8" %>
import { useState, useEffect, useRef } from "react";

// ─── Mock data ───────────────────────────────────────────────────────────────
const CATEGORIES = [
  { id: 0, label: "Tất cả" },
  { id: 1, label: "Kháng sinh" },
  { id: 2, label: "Giảm đau" },
  { id: 3, label: "Vitamin" },
  { id: 4, label: "Tim mạch" },
  { id: 5, label: "Tiêu hóa" },
];

const MEDICINES_DATA = [
  { id: 1, catId: 1, name: "Amoxicillin 500mg", unit: "Viên", price: 4500, stock: 120, rx: false, code: "AMO500" },
  { id: 2, catId: 1, name: "Augmentin 625mg", unit: "Viên", price: 12000, stock: 80, rx: true, code: "AUG625" },
  { id: 3, catId: 1, name: "Azithromycin 250mg", unit: "Viên", price: 8500, stock: 0, rx: true, code: "AZI250" },
  { id: 4, catId: 2, name: "Paracetamol 500mg", unit: "Viên", price: 1500, stock: 500, rx: false, code: "PAR500" },
  { id: 5, catId: 2, name: "Ibuprofen 400mg", unit: "Viên", price: 3200, stock: 200, rx: false, code: "IBU400" },
  { id: 6, catId: 2, name: "Diclofenac 50mg", unit: "Viên", price: 2800, stock: 150, rx: false, code: "DIC050" },
  { id: 7, catId: 3, name: "Vitamin C 1000mg", unit: "Viên", price: 5500, stock: 300, rx: false, code: "VITC1G" },
  { id: 8, catId: 3, name: "Vitamin D3 1000IU", unit: "Viên", price: 7200, stock: 90, rx: false, code: "VITD3" },
  { id: 9, catId: 3, name: "Vitamin B Complex", unit: "Viên", price: 3000, stock: 250, rx: false, code: "VITB" },
  { id: 10, catId: 4, name: "Amlodipine 5mg", unit: "Viên", price: 4200, stock: 60, rx: true, code: "AML005" },
  { id: 11, catId: 4, name: "Atorvastatin 20mg", unit: "Viên", price: 9500, stock: 45, rx: true, code: "ATO020" },
  { id: 12, catId: 5, name: "Omeprazole 20mg", unit: "Viên", price: 3800, stock: 180, rx: false, code: "OMP020" },
  { id: 13, catId: 5, name: "Domperidone 10mg", unit: "Viên", price: 2200, stock: 220, rx: false, code: "DOM010" },
  { id: 14, catId: 2, name: "Aspirin 81mg", unit: "Viên", price: 1800, stock: 400, rx: false, code: "ASP081" },
  { id: 15, catId: 3, name: "Omega-3 1000mg", unit: "Viên", price: 8800, stock: 110, rx: false, code: "OMG1G" },
  { id: 16, catId: 1, name: "Ciprofloxacin 500mg", unit: "Viên", price: 6500, stock: 70, rx: true, code: "CIP500" },
];

const PAYMENT_METHODS = [
  { value: "CASH", label: "💵 Tiền mặt" },
  { value: "CARD", label: "💳 Thẻ ngân hàng" },
  { value: "TRANSFER", label: "🏦 Chuyển khoản" },
  { value: "EWALLET", label: "📱 Ví điện tử" },
  { value: "QR_CODE", label: "📷 QR Code" },
];

const fmt = (n) => new Intl.NumberFormat("vi-VN").format(n) + "đ";

// ─── Sub-components ───────────────────────────────────────────────────────────
function RxBadge() {
  return (
    <span style={{ fontSize: 9, background: "#FEF3C7", color: "#92400E", border: "1px solid #FCD34D", borderRadius: 4, padding: "1px 5px", fontWeight: 700 }}>
      Rx
    </span>
  );
}

function StockBadge({ stock }) {
  if (stock === 0) return <span style={{ fontSize: 10, background: "#FEE2E2", color: "#991B1B", borderRadius: 4, padding: "1px 6px", fontWeight: 600 }}>Hết hàng</span>;
  if (stock <= 20) return <span style={{ fontSize: 10, background: "#FEF3C7", color: "#92400E", borderRadius: 4, padding: "1px 6px", fontWeight: 600 }}>Còn {stock}</span>;
  return <span style={{ fontSize: 10, background: "#D1FAE5", color: "#065F46", borderRadius: 4, padding: "1px 6px", fontWeight: 600 }}>Còn {stock}</span>;
}

// ─── Main Component ───────────────────────────────────────────────────────────
export default function POSBill() {
  const [activeCat, setActiveCat] = useState(0);
  const [search, setSearch] = useState("");
  const [cart, setCart] = useState([]);
  const [discount, setDiscount] = useState("");
  const [payMethod, setPayMethod] = useState("CASH");
  const [customerPhone, setCustomerPhone] = useState("");
  const [customerName, setCustomerName] = useState("");
  const [customerId, setCustomerId] = useState(null);
  const [showSuccess, setShowSuccess] = useState(false);
  const [successData, setSuccessData] = useState(null);
  const [showConfirm, setShowConfirm] = useState(false);
  const [cashReceived, setCashReceived] = useState("");
  const [noteText, setNoteText] = useState("");
  const searchRef = useRef(null);

  // Filter medicines
  const filtered = MEDICINES_DATA.filter((m) => {
    const matchCat = activeCat === 0 || m.catId === activeCat;
    const matchSearch =
      !search ||
      m.name.toLowerCase().includes(search.toLowerCase()) ||
      m.code.toLowerCase().includes(search.toLowerCase());
    return matchCat && matchSearch;
  });

  // Cart ops
  const addToCart = (med) => {
    if (med.stock === 0) return;
    setCart((prev) => {
      const existing = prev.find((i) => i.id === med.id);
      if (existing) {
        if (existing.qty >= med.stock) return prev;
        return prev.map((i) => i.id === med.id ? { ...i, qty: i.qty + 1 } : i);
      }
      return [...prev, { ...med, qty: 1 }];
    });
  };

  const removeFromCart = (id) => setCart((p) => p.filter((i) => i.id !== id));

  const updateQty = (id, val) => {
    const n = parseInt(val);
    if (isNaN(n) || n <= 0) { removeFromCart(id); return; }
    const med = MEDICINES_DATA.find((m) => m.id === id);
    if (med && n > med.stock) return;
    setCart((p) => p.map((i) => i.id === id ? { ...i, qty: n } : i));
  };

  const clearCart = () => {
    setCart([]);
    setDiscount("");
    setCustomerPhone("");
    setCustomerName("");
    setCustomerId(null);
    setNoteText("");
    setCashReceived("");
  };

  // Totals
  const subtotal = cart.reduce((s, i) => s + i.price * i.qty, 0);
  const discountAmt = Math.min(parseFloat(discount) || 0, subtotal);
  const total = subtotal - discountAmt;
  const change = payMethod === "CASH" && cashReceived ? Math.max(0, parseFloat(cashReceived) - total) : 0;

  // Customer lookup (mock)
  const lookupCustomer = () => {
    if (customerPhone === "0901234567") {
      setCustomerName("Nguyễn Văn A");
      setCustomerId(1);
    } else if (customerPhone === "0987654321") {
      setCustomerName("Trần Thị B");
      setCustomerId(2);
    } else {
      setCustomerName("");
      setCustomerId(null);
    }
  };

  // Complete sale
  const handleCompleteSale = () => {
    if (cart.length === 0) return;
    setShowConfirm(true);
  };

  const confirmSale = () => {
    const invoiceId = Math.floor(Math.random() * 90000) + 10000;
    setSuccessData({
      invoiceCode: `HD${String(invoiceId).padStart(6, "0")}`,
      total,
      items: cart.length,
      payMethod: PAYMENT_METHODS.find((p) => p.value === payMethod)?.label,
    });
    setShowConfirm(false);
    setShowSuccess(true);
    clearCart();
  };

  const closeSuccess = () => setShowSuccess(false);

  // Keyboard shortcut F2 = focus search
  useEffect(() => {
    const handler = (e) => { if (e.key === "F2") searchRef.current?.focus(); };
    window.addEventListener("keydown", handler);
    return () => window.removeEventListener("keydown", handler);
  }, []);

  // ─── Styles ──────────────────────────────────────────────────────────────
  const css = {
    // Layout
    root: { display: "flex", height: "100vh", fontFamily: "'Segoe UI', Arial, sans-serif", background: "#F0F4F8", overflow: "hidden" },
    sidebar: { width: 64, background: "linear-gradient(180deg,#1E3A8A 0%,#1558A8 60%,#3B82F6 100%)", display: "flex", flexDirection: "column", alignItems: "center", padding: "16px 0", gap: 8, flexShrink: 0 },
    sideIcon: { width: 40, height: 40, borderRadius: 10, display: "flex", alignItems: "center", justifyContent: "center", cursor: "pointer", fontSize: 18, color: "rgba(255,255,255,0.7)", transition: "all .15s" },
    main: { flex: 1, display: "flex", overflow: "hidden" },
    // Medicine panel
    medPanel: { flex: 1, display: "flex", flexDirection: "column", overflow: "hidden", background: "#F8FAFC" },
    topBar: { background: "#fff", borderBottom: "1px solid #E2E8F0", padding: "10px 16px", display: "flex", alignItems: "center", gap: 10 },
    searchBox: { flex: 1, height: 38, border: "1.5px solid #CBD5E1", borderRadius: 8, padding: "0 12px 0 36px", fontSize: 13.5, outline: "none", background: "#F8FAFC", transition: "border .15s" },
    catRow: { display: "flex", gap: 8, padding: "10px 16px 0", flexWrap: "wrap" },
    catBtn: (active) => ({
      padding: "6px 16px", borderRadius: 20, border: active ? "none" : "1.5px solid #CBD5E1",
      background: active ? "linear-gradient(135deg,#1558A8,#3B82F6)" : "#fff",
      color: active ? "#fff" : "#475569", fontWeight: active ? 700 : 500,
      fontSize: 13, cursor: "pointer", transition: "all .15s",
      boxShadow: active ? "0 2px 8px rgba(21,88,168,.3)" : "none",
    }),
    grid: { display: "grid", gridTemplateColumns: "repeat(auto-fill,minmax(160px,1fr))", gap: 10, padding: "12px 16px", overflowY: "auto", flex: 1 },
    medCard: (outOfStock) => ({
      background: outOfStock ? "#F8FAFC" : "#fff",
      border: outOfStock ? "1.5px dashed #CBD5E1" : "1.5px solid #E2E8F0",
      borderRadius: 12, padding: "12px 10px 10px",
      cursor: outOfStock ? "not-allowed" : "pointer",
      transition: "all .15s",
      opacity: outOfStock ? 0.6 : 1,
      display: "flex", flexDirection: "column", gap: 6,
    }),
    // Bill panel
    billPanel: { width: 340, background: "#fff", borderLeft: "1px solid #E2E8F0", display: "flex", flexDirection: "column", flexShrink: 0 },
    billHeader: { background: "linear-gradient(135deg,#1E3A8A,#1558A8)", padding: "14px 16px", color: "#fff" },
    cartArea: { flex: 1, overflowY: "auto", padding: "10px 12px" },
    cartRow: { display: "flex", alignItems: "flex-start", gap: 6, padding: "8px 0", borderBottom: "1px solid #F1F5F9" },
    qtyBtn: { width: 26, height: 26, borderRadius: 6, border: "1.5px solid #CBD5E1", background: "#F8FAFC", cursor: "pointer", fontWeight: 700, fontSize: 14, display: "flex", alignItems: "center", justifyContent: "center" },
    qtyInput: { width: 38, height: 26, border: "1.5px solid #CBD5E1", borderRadius: 6, textAlign: "center", fontSize: 13, fontWeight: 700, outline: "none" },
    payArea: { padding: "12px", borderTop: "1px solid #E2E8F0", background: "#F8FAFC" },
    payBtn: { width: "100%", height: 46, borderRadius: 10, border: "none", background: cart.length === 0 ? "#CBD5E1" : "linear-gradient(135deg,#1558A8,#3B82F6)", color: "#fff", fontWeight: 700, fontSize: 15, cursor: cart.length === 0 ? "not-allowed" : "pointer", display: "flex", alignItems: "center", justifyContent: "center", gap: 6, transition: "all .15s" },
    // Modal
    overlay: { position: "fixed", inset: 0, background: "rgba(0,0,0,.45)", zIndex: 999, display: "flex", alignItems: "center", justifyContent: "center" },
    modal: { background: "#fff", borderRadius: 16, padding: 24, width: 360, boxShadow: "0 20px 60px rgba(0,0,0,.25)" },
    successIcon: { width: 64, height: 64, borderRadius: "50%", background: "linear-gradient(135deg,#059669,#34D399)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 30, margin: "0 auto 12px" },
  };

  const emptyCart = cart.length === 0;

  return (
    <div style={css.root}>
      {/* ── Sidebar ── */}
      <div style={css.sidebar}>
        <div style={{ color: "#fff", fontWeight: 900, fontSize: 11, letterSpacing: 1, marginBottom: 8, textAlign: "center", lineHeight: 1.2 }}>
          💊<br />MV
        </div>
        {[
          { icon: "🏠", tip: "Dashboard" },
          { icon: "💊", tip: "POS Bán hàng", active: true },
          { icon: "📦", tip: "Kho thuốc" },
          { icon: "📋", tip: "Hóa đơn" },
          { icon: "👥", tip: "Khách hàng" },
          { icon: "📊", tip: "Báo cáo" },
        ].map((item, i) => (
          <div key={i} title={item.tip} style={{ ...css.sideIcon, background: item.active ? "rgba(255,255,255,.25)" : "transparent", color: item.active ? "#fff" : "rgba(255,255,255,.65)", borderRadius: 10 }}>
            {item.icon}
          </div>
        ))}
        <div style={{ flex: 1 }} />
        <div style={{ ...css.sideIcon, color: "rgba(255,255,255,.6)" }} title="Đăng xuất">⏻</div>
      </div>

      {/* ── Main ── */}
      <div style={css.main}>
        {/* ── Medicine panel ── */}
        <div style={css.medPanel}>
          {/* Top bar */}
          <div style={css.topBar}>
            <div style={{ position: "relative", flex: 1 }}>
              <span style={{ position: "absolute", left: 10, top: "50%", transform: "translateY(-50%)", fontSize: 15, color: "#94A3B8" }}>🔍</span>
              <input
                ref={searchRef}
                style={css.searchBox}
                placeholder="Tìm thuốc theo tên hoặc mã... (F2)"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
              />
            </div>
            <div style={{ fontSize: 12, color: "#94A3B8", whiteSpace: "nowrap" }}>
              {filtered.length} thuốc
            </div>
            <div style={{ fontSize: 12, color: "#64748B", background: "#F1F5F9", borderRadius: 8, padding: "4px 10px", whiteSpace: "nowrap" }}>
              📅 {new Date().toLocaleDateString("vi-VN")}
            </div>
          </div>

          {/* Category chips */}
          <div style={css.catRow}>
            {CATEGORIES.map((c) => (
              <button key={c.id} style={css.catBtn(activeCat === c.id)} onClick={() => setActiveCat(c.id)}>
                {c.label}
              </button>
            ))}
          </div>

          {/* Medicine grid */}
          <div style={css.grid}>
            {filtered.length === 0 && (
              <div style={{ gridColumn: "1/-1", textAlign: "center", color: "#94A3B8", padding: "48px 0" }}>
                <div style={{ fontSize: 36 }}>🔍</div>
                <div style={{ fontSize: 14, marginTop: 8 }}>Không tìm thấy thuốc nào</div>
              </div>
            )}
            {filtered.map((med) => {
              const inCart = cart.find((i) => i.id === med.id);
              return (
                <div
                  key={med.id}
                  style={{
                    ...css.medCard(med.stock === 0),
                    border: inCart ? "2px solid #1558A8" : (med.stock === 0 ? "1.5px dashed #CBD5E1" : "1.5px solid #E2E8F0"),
                    boxShadow: inCart ? "0 0 0 3px rgba(21,88,168,.12)" : "none",
                  }}
                  onClick={() => addToCart(med)}
                >
                  <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", gap: 4 }}>
                    <span style={{ fontSize: 10, color: "#94A3B8", fontFamily: "monospace" }}>{med.code}</span>
                    <div style={{ display: "flex", gap: 3, flexShrink: 0 }}>
                      {med.rx && <RxBadge />}
                      {inCart && <span style={{ fontSize: 9, background: "#DBEAFE", color: "#1E40AF", borderRadius: 4, padding: "1px 5px", fontWeight: 700 }}>×{inCart.qty}</span>}
                    </div>
                  </div>
                  <div style={{ fontSize: 13, fontWeight: 700, color: "#0F172A", lineHeight: 1.3 }}>{med.name}</div>
                  <div style={{ fontSize: 12, color: "#64748B" }}>{med.unit}</div>
                  <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginTop: 2 }}>
                    <span style={{ fontSize: 14, fontWeight: 800, color: "#1558A8" }}>{fmt(med.price)}</span>
                    <StockBadge stock={med.stock} />
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* ── Bill panel ── */}
        <div style={css.billPanel}>
          {/* Header */}
          <div style={css.billHeader}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <div>
                <div style={{ fontWeight: 800, fontSize: 15 }}>🧾 Hóa đơn bán hàng</div>
                <div style={{ fontSize: 11, opacity: 0.75, marginTop: 2 }}>{cart.length} sản phẩm • {fmt(total)}</div>
              </div>
              {!emptyCart && (
                <button onClick={clearCart} style={{ background: "rgba(255,255,255,.2)", border: "1px solid rgba(255,255,255,.4)", color: "#fff", borderRadius: 8, padding: "4px 10px", cursor: "pointer", fontSize: 12 }}>
                  🗑 Xóa
                </button>
              )}
            </div>
          </div>

          {/* Customer lookup */}
          <div style={{ padding: "10px 12px", borderBottom: "1px solid #F1F5F9", background: "#FAFBFC" }}>
            <div style={{ fontSize: 11, fontWeight: 700, color: "#64748B", marginBottom: 5, textTransform: "uppercase", letterSpacing: .5 }}>Khách hàng</div>
            <div style={{ display: "flex", gap: 6 }}>
              <input
                style={{ flex: 1, height: 32, border: "1.5px solid #CBD5E1", borderRadius: 7, padding: "0 8px", fontSize: 12.5, outline: "none" }}
                placeholder="SĐT khách hàng..."
                value={customerPhone}
                onChange={(e) => setCustomerPhone(e.target.value)}
                onKeyDown={(e) => e.key === "Enter" && lookupCustomer()}
              />
              <button onClick={lookupCustomer} style={{ height: 32, padding: "0 10px", borderRadius: 7, border: "none", background: "#1558A8", color: "#fff", cursor: "pointer", fontSize: 13, fontWeight: 700 }}>🔍</button>
            </div>
            {customerName && (
              <div style={{ marginTop: 5, fontSize: 12, color: "#059669", fontWeight: 600, display: "flex", alignItems: "center", gap: 4 }}>
                ✅ {customerName}
                <button onClick={() => { setCustomerName(""); setCustomerId(null); setCustomerPhone(""); }} style={{ fontSize: 10, background: "none", border: "none", cursor: "pointer", color: "#94A3B8" }}>✕</button>
              </div>
            )}
            {customerPhone && !customerName && (
              <div style={{ marginTop: 5, fontSize: 12, color: "#94A3B8" }}>Không tìm thấy. Bán lẻ không tên.</div>
            )}
          </div>

          {/* Cart items */}
          <div style={css.cartArea}>
            {emptyCart ? (
              <div style={{ textAlign: "center", color: "#CBD5E1", padding: "40px 0" }}>
                <div style={{ fontSize: 40 }}>🛒</div>
                <div style={{ fontSize: 13, marginTop: 8 }}>Giỏ hàng trống</div>
                <div style={{ fontSize: 11, marginTop: 4, color: "#94A3B8" }}>Bấm vào thuốc để thêm</div>
              </div>
            ) : (
              cart.map((item) => (
                <div key={item.id} style={css.cartRow}>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontSize: 12.5, fontWeight: 600, color: "#0F172A", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>
                      {item.name}
                    </div>
                    <div style={{ fontSize: 11, color: "#64748B" }}>{fmt(item.price)} / {item.unit}</div>
                    <div style={{ fontSize: 12, fontWeight: 700, color: "#1558A8", marginTop: 2 }}>{fmt(item.price * item.qty)}</div>
                  </div>
                  <div style={{ display: "flex", alignItems: "center", gap: 4, flexShrink: 0 }}>
                    <button style={css.qtyBtn} onClick={() => updateQty(item.id, item.qty - 1)}>−</button>
                    <input
                      style={css.qtyInput}
                      value={item.qty}
                      onChange={(e) => updateQty(item.id, e.target.value)}
                      type="number"
                      min={1}
                    />
                    <button style={css.qtyBtn} onClick={() => updateQty(item.id, item.qty + 1)}>+</button>
                    <button onClick={() => removeFromCart(item.id)} style={{ width: 24, height: 24, borderRadius: 6, border: "none", background: "#FEE2E2", color: "#DC2626", cursor: "pointer", fontSize: 12, fontWeight: 700, display: "flex", alignItems: "center", justifyContent: "center" }}>✕</button>
                  </div>
                </div>
              ))
            )}
          </div>

          {/* Payment area */}
          <div style={css.payArea}>
            {/* Discount */}
            <div style={{ marginBottom: 8 }}>
              <label style={{ fontSize: 11, color: "#64748B", fontWeight: 600, textTransform: "uppercase", letterSpacing: .5 }}>Giảm giá (đ)</label>
              <input
                style={{ width: "100%", height: 32, border: "1.5px solid #CBD5E1", borderRadius: 7, padding: "0 10px", fontSize: 13, outline: "none", marginTop: 4, boxSizing: "border-box" }}
                placeholder="0"
                value={discount}
                type="number"
                min={0}
                onChange={(e) => setDiscount(e.target.value)}
              />
            </div>

            {/* Payment method */}
            <div style={{ marginBottom: 8 }}>
              <label style={{ fontSize: 11, color: "#64748B", fontWeight: 600, textTransform: "uppercase", letterSpacing: .5 }}>Phương thức</label>
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 5, marginTop: 4 }}>
                {PAYMENT_METHODS.map((p) => (
                  <button
                    key={p.value}
                    style={{
                      padding: "6px 4px", borderRadius: 7, border: payMethod === p.value ? "2px solid #1558A8" : "1.5px solid #CBD5E1",
                      background: payMethod === p.value ? "#EFF6FF" : "#fff",
                      color: payMethod === p.value ? "#1558A8" : "#475569",
                      fontWeight: payMethod === p.value ? 700 : 500,
                      fontSize: 11, cursor: "pointer",
                    }}
                    onClick={() => setPayMethod(p.value)}
                  >
                    {p.label}
                  </button>
                ))}
              </div>
            </div>

            {/* Cash received */}
            {payMethod === "CASH" && (
              <div style={{ marginBottom: 8 }}>
                <label style={{ fontSize: 11, color: "#64748B", fontWeight: 600, textTransform: "uppercase", letterSpacing: .5 }}>Tiền khách đưa</label>
                <input
                  style={{ width: "100%", height: 32, border: "1.5px solid #CBD5E1", borderRadius: 7, padding: "0 10px", fontSize: 13, outline: "none", marginTop: 4, boxSizing: "border-box" }}
                  placeholder="0"
                  value={cashReceived}
                  type="number"
                  onChange={(e) => setCashReceived(e.target.value)}
                />
                {cashReceived && parseFloat(cashReceived) >= total && (
                  <div style={{ marginTop: 4, fontSize: 12, fontWeight: 700, color: "#059669" }}>
                    💰 Tiền thừa: {fmt(change)}
                  </div>
                )}
              </div>
            )}

            {/* Note */}
            <div style={{ marginBottom: 10 }}>
              <textarea
                style={{ width: "100%", height: 40, border: "1.5px solid #CBD5E1", borderRadius: 7, padding: "6px 10px", fontSize: 12, outline: "none", resize: "none", boxSizing: "border-box", fontFamily: "inherit" }}
                placeholder="Ghi chú hóa đơn..."
                value={noteText}
                onChange={(e) => setNoteText(e.target.value)}
              />
            </div>

            {/* Summary */}
            <div style={{ background: "#F8FAFC", borderRadius: 8, padding: "8px 10px", marginBottom: 10, fontSize: 12.5 }}>
              <div style={{ display: "flex", justifyContent: "space-between", color: "#64748B", marginBottom: 3 }}>
                <span>Tạm tính</span><span>{fmt(subtotal)}</span>
              </div>
              {discountAmt > 0 && (
                <div style={{ display: "flex", justifyContent: "space-between", color: "#DC2626", marginBottom: 3 }}>
                  <span>Giảm giá</span><span>−{fmt(discountAmt)}</span>
                </div>
              )}
              <div style={{ display: "flex", justifyContent: "space-between", fontWeight: 800, fontSize: 15, color: "#0F172A", borderTop: "1px solid #E2E8F0", paddingTop: 6, marginTop: 4 }}>
                <span>Tổng cộng</span><span style={{ color: "#1558A8" }}>{fmt(total)}</span>
              </div>
            </div>

            {/* CTA */}
            <button style={css.payBtn} onClick={handleCompleteSale} disabled={emptyCart}>
              <span>⚡</span> Thanh toán {!emptyCart && fmt(total)}
            </button>
          </div>
        </div>
      </div>

      {/* ── Confirm Modal ── */}
      {showConfirm && (
        <div style={css.overlay} onClick={() => setShowConfirm(false)}>
          <div style={css.modal} onClick={(e) => e.stopPropagation()}>
            <div style={{ fontWeight: 800, fontSize: 17, marginBottom: 14, color: "#0F172A" }}>⚡ Xác nhận thanh toán</div>
            <div style={{ background: "#F8FAFC", borderRadius: 10, padding: "12px 14px", marginBottom: 14, fontSize: 13 }}>
              <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 5 }}>
                <span style={{ color: "#64748B" }}>Số sản phẩm</span><span style={{ fontWeight: 700 }}>{cart.length}</span>
              </div>
              <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 5 }}>
                <span style={{ color: "#64748B" }}>Phương thức</span>
                <span style={{ fontWeight: 700 }}>{PAYMENT_METHODS.find((p) => p.value === payMethod)?.label}</span>
              </div>
              {customerName && (
                <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 5 }}>
                  <span style={{ color: "#64748B" }}>Khách hàng</span><span style={{ fontWeight: 700 }}>{customerName}</span>
                </div>
              )}
              <div style={{ display: "flex", justifyContent: "space-between", borderTop: "1px solid #E2E8F0", paddingTop: 8, marginTop: 4 }}>
                <span style={{ color: "#0F172A", fontWeight: 700, fontSize: 15 }}>Tổng cộng</span>
                <span style={{ color: "#1558A8", fontWeight: 900, fontSize: 17 }}>{fmt(total)}</span>
              </div>
            </div>
            <div style={{ display: "flex", gap: 8 }}>
              <button onClick={() => setShowConfirm(false)} style={{ flex: 1, height: 40, borderRadius: 9, border: "1.5px solid #CBD5E1", background: "#fff", cursor: "pointer", fontSize: 14, fontWeight: 600 }}>
                Hủy
              </button>
              <button onClick={confirmSale} style={{ flex: 2, height: 40, borderRadius: 9, border: "none", background: "linear-gradient(135deg,#1558A8,#3B82F6)", color: "#fff", cursor: "pointer", fontSize: 14, fontWeight: 700 }}>
                ✅ Xác nhận & In bill
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ── Success Modal ── */}
      {showSuccess && successData && (
        <div style={css.overlay}>
          <div style={{ ...css.modal, textAlign: "center" }}>
            <div style={css.successIcon}>✅</div>
            <div style={{ fontWeight: 800, fontSize: 18, color: "#0F172A", marginBottom: 4 }}>Thanh toán thành công!</div>
            <div style={{ fontSize: 13, color: "#64748B", marginBottom: 16 }}>Hóa đơn đã được lưu vào hệ thống</div>
            <div style={{ background: "linear-gradient(135deg,#F0FDF4,#DCFCE7)", border: "1.5px solid #86EFAC", borderRadius: 12, padding: "14px 16px", marginBottom: 16, textAlign: "left" }}>
              <div style={{ fontSize: 12, color: "#64748B", marginBottom: 3 }}>MÃ HÓA ĐƠN</div>
              <div style={{ fontWeight: 900, fontSize: 22, color: "#1558A8", letterSpacing: 2 }}>{successData.invoiceCode}</div>
              <div style={{ display: "flex", justifyContent: "space-between", marginTop: 8, fontSize: 13 }}>
                <span style={{ color: "#64748B" }}>{successData.items} sản phẩm • {successData.payMethod}</span>
                <span style={{ fontWeight: 800, color: "#059669", fontSize: 15 }}>{fmt(successData.total)}</span>
              </div>
            </div>
            <div style={{ display: "flex", gap: 8 }}>
              <button onClick={closeSuccess} style={{ flex: 1, height: 40, borderRadius: 9, border: "1.5px solid #CBD5E1", background: "#fff", cursor: "pointer", fontSize: 13, fontWeight: 600 }}>
                🖨 In bill
              </button>
              <button onClick={closeSuccess} style={{ flex: 1, height: 40, borderRadius: 9, border: "none", background: "linear-gradient(135deg,#1558A8,#3B82F6)", color: "#fff", cursor: "pointer", fontSize: 13, fontWeight: 700 }}>
                ✅ Đóng
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}