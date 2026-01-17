package com.group10.vnrailway.controller.manager;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Pattern;

import javax.sql.DataSource;

@Controller
@RequestMapping("/manager/settings")
@RequiredArgsConstructor
@Slf4j
public class ManagerSettingsController {

    private final DataSource dataSource;
    
    // ✅ FIX: Validate mã tham số pattern
    private static final Pattern VALID_THAM_SO_PATTERN = Pattern.compile("^(GV|TS)\\d{3}$");

    @GetMapping
    public String getSettings(Model model) {
        try {
            // Lấy tất cả tham số (bao gồm cả giá vé)
            List<Map<String, Object>> allThamSo = getAllThamSo();
            log.info("Loaded {} total parameters", allThamSo.size());
            
            model.addAttribute("allThamSo", allThamSo);
            
            return "pages/manager/settings/index";
        } catch (SQLException e) {
            log.error("Error loading settings", e);
            model.addAttribute("errorMessage", "Lỗi tải dữ liệu: " + e.getMessage());
            return "pages/manager/settings/index";
        }
    }

    @PostMapping("/update-giave")
    public String updateGiaVe(@RequestParam Map<String, String> allParams, 
                              RedirectAttributes redirectAttributes) {
        int successCount = 0;
        int errorCount = 0;
        StringBuilder errorMessages = new StringBuilder();
        
        try (Connection conn = dataSource.getConnection()) {
            conn.setAutoCommit(false);
            
            try {
                for (Map.Entry<String, String> entry : allParams.entrySet()) {
                    String key = entry.getKey();
                    
                    // Skip CSRF token
                    if (key.equals("_csrf")) continue;
                    
                    if (key.startsWith("giave_")) {
                        String maGiaVe = key.substring(6);
                        
                        // ✅ FIX: VALIDATE mã tham số để prevent SQL injection
                        if (!VALID_THAM_SO_PATTERN.matcher(maGiaVe).matches()) {
                            log.warn("Invalid parameter code: {}", maGiaVe);
                            errorCount++;
                            errorMessages.append(maGiaVe).append("(invalid code) ");
                            continue;
                        }
                        
                        try {
                            double giaVe = Double.parseDouble(entry.getValue());
                            
                            // ✅ THÊM: Server-side validation
                            if (giaVe < 100 || giaVe > 10000000) {
                                errorCount++;
                                errorMessages.append(maGiaVe).append("(giá không hợp lệ) ");
                                log.warn("Invalid price for {}: {}", maGiaVe, giaVe);
                                continue;
                            }
                            
                            try (CallableStatement stmt = conn.prepareCall("{CALL sp_UpdateGiaVeCoban(?, ?)}")) {
                                stmt.setString(1, maGiaVe);
                                stmt.setDouble(2, giaVe);
                                
                                int returnCode = stmt.executeUpdate();
                                
                                if (returnCode == 0 || returnCode == -1) {
                                    successCount++;
                                } else {
                                    errorCount++;
                                    errorMessages.append(maGiaVe).append(" ");
                                }
                            }
                        } catch (NumberFormatException e) {
                            errorCount++;
                            errorMessages.append(maGiaVe).append("(format) ");
                            log.error("Invalid number format for {}: {}", maGiaVe, entry.getValue());
                        } catch (SQLException e) {
                            errorCount++;
                            errorMessages.append(maGiaVe).append("(SQL) ");
                            log.error("SQL error updating {}: {}", maGiaVe, e.getMessage());
                        }
                    }
                }
                
                conn.commit();
                
                if (errorCount > 0) {
                    redirectAttributes.addFlashAttribute("errorMessage", 
                        String.format("Cập nhật thành công %d giá vé, %d giá vé lỗi: %s", 
                            successCount, errorCount, errorMessages.toString()));
                } else {
                    redirectAttributes.addFlashAttribute("successMessage", 
                        String.format("Cập nhật thành công %d giá vé!", successCount));
                }
                
            } catch (Exception e) {
                conn.rollback();
                log.error("Transaction failed, rolling back", e);
                redirectAttributes.addFlashAttribute("errorMessage", "Lỗi cập nhật: " + e.getMessage());
            } finally {
                conn.setAutoCommit(true);
            }
            
        } catch (SQLException e) {
            log.error("Database connection error", e);
            redirectAttributes.addFlashAttribute("errorMessage", "Lỗi kết nối: " + e.getMessage());
        }
        
        return "redirect:/manager/settings";
    }

    @PostMapping("/update-thamso")
    public String updateThamSo(@RequestParam Map<String, String> allParams, 
                               RedirectAttributes redirectAttributes) {
        int successCount = 0;
        int errorCount = 0;
        StringBuilder errorMessages = new StringBuilder();
        
        log.info("Starting tham so update with {} parameters", allParams.size());
        
        try (Connection conn = dataSource.getConnection()) {
            conn.setAutoCommit(false);
            
            try {
                // Collect all updates first
                Map<String, Double> updates = new HashMap<>();
                
                for (Map.Entry<String, String> entry : allParams.entrySet()) {
                    String key = entry.getKey();
                    
                    // Skip CSRF token
                    if (key.equals("_csrf")) continue;
                    
                    if (key.startsWith("thamso_")) {
                        String maThamSo = key.substring(7); // "thamso_" có 7 ký tự
                        
                        // Validate mã tham số
                        if (!VALID_THAM_SO_PATTERN.matcher(maThamSo).matches()) {
                            log.warn("Invalid parameter code: {}", maThamSo);
                            errorCount++;
                            errorMessages.append(maThamSo).append("(mã không hợp lệ) ");
                            continue;
                        }
                        
                        try {
                            double giaTri = Double.parseDouble(entry.getValue());
                            
                            // Server-side validation
                            if (giaTri <= 0) {
                                errorCount++;
                                errorMessages.append(maThamSo).append("(phải > 0) ");
                                continue;
                            }
                            
                            // Xử lý tỷ lệ % - CHUYỂN ĐỔI: user nhập 15 → DB lưu 0.15
                            if (maThamSo.matches("TS009|TS010|TS011")) {
                                if (giaTri < 0 || giaTri > 100) {
                                    errorCount++;
                                    errorMessages.append(maThamSo).append("(phải 0-100%) ");
                                    continue;
                                }
                                giaTri = giaTri / 100.0;
                            }
                            
                            // TS007: Phí đổi vé 0-100%
                            if (maThamSo.equals("TS007")) {
                                if (giaTri < 0 || giaTri > 100) {
                                    errorCount++;
                                    errorMessages.append(maThamSo).append("(phải 0-100%) ");
                                    continue;
                                }
                            }
                            
                            updates.put(maThamSo, giaTri);
                            
                        } catch (NumberFormatException e) {
                            errorCount++;
                            errorMessages.append(maThamSo).append("(định dạng sai) ");
                            log.error("Invalid number format for {}: {}", maThamSo, entry.getValue());
                        }
                    }
                }
                
                log.info("Validated {} parameters for update", updates.size());
                
                // Update each parameter using sp_UpdateThamSo (includes validation + update)
                for (Map.Entry<String, Double> update : updates.entrySet()) {
                    String maThamSo = update.getKey();
                    double giaTri = update.getValue();
                    
                    try (CallableStatement stmt = conn.prepareCall("{? = CALL sp_UpdateThamSo(?, ?, ?)}")) {
                        stmt.registerOutParameter(1, Types.INTEGER); // Return code
                        stmt.setString(2, maThamSo);
                        stmt.setDouble(3, giaTri);
                        stmt.registerOutParameter(4, Types.NVARCHAR); // ThongBao
                        
                        stmt.execute();
                        
                        int returnCode = stmt.getInt(1);
                        String thongBao = stmt.getString(4);
                        
                        log.info("{}: return={}, message={}", maThamSo, returnCode, thongBao);
                        
                        if (returnCode == 0) {
                            successCount++;
                        } else {
                            errorCount++;
                            errorMessages.append(maThamSo).append("(").append(thongBao).append(") ");
                        }
                    } catch (SQLException e) {
                        errorCount++;
                        errorMessages.append(maThamSo).append("(SQL error) ");
                        log.error("SQL error updating {}: {}", maThamSo, e.getMessage());
                    }
                }
                
                conn.commit();
                
                if (errorCount > 0) {
                    redirectAttributes.addFlashAttribute("errorMessage", 
                        String.format("Cập nhật thành công %d tham số, %d tham số lỗi: %s", 
                            successCount, errorCount, errorMessages.toString()));
                } else {
                    redirectAttributes.addFlashAttribute("successMessage", 
                        String.format("Cập nhật thành công %d tham số hệ thống!", successCount));
                }
                
            } catch (Exception e) {
                conn.rollback();
                log.error("Transaction failed, rolling back", e);
                redirectAttributes.addFlashAttribute("errorMessage", "Lỗi cập nhật: " + e.getMessage());
            } finally {
                conn.setAutoCommit(true);
            }
            
        } catch (SQLException e) {
            log.error("Database connection error", e);
            redirectAttributes.addFlashAttribute("errorMessage", "Lỗi kết nối: " + e.getMessage());
        }
        
        return "redirect:/manager/settings";
    }

    /**
     * Cập nhật khuyến mãi (TS009, TS010, TS011) sử dụng stored procedure riêng
     */
    @PostMapping("/update-khuyenmai")
    public String updateKhuyenMai(@RequestParam Map<String, String> allParams, 
                                   RedirectAttributes redirectAttributes) {
        int successCount = 0;
        int errorCount = 0;
        StringBuilder messages = new StringBuilder();
        
        log.info("Starting promotion update with {} parameters", allParams.size());
        
        try (Connection conn = dataSource.getConnection()) {
            conn.setAutoCommit(false);
            
            try {
                // Chỉ xử lý 3 mã khuyến mãi: TS009, TS010, TS011
                String[] promotionCodes = {"TS009", "TS010", "TS011"};
                
                for (String maThamSo : promotionCodes) {
                    String paramName = "khuyenmai_" + maThamSo;
                    String valueStr = allParams.get(paramName);
                    
                    // Bỏ qua nếu không có giá trị
                    if (valueStr == null || valueStr.trim().isEmpty()) {
                        continue;
                    }
                    
                    try {
                        double giaTriNhap = Double.parseDouble(valueStr);
                        
                        // Gọi usp_CapNhatKhuyenMai
                        try (CallableStatement stmt = conn.prepareCall("{? = CALL usp_CapNhatKhuyenMai(?, ?, ?)}")) {
                            stmt.registerOutParameter(1, Types.INTEGER);      // Return code
                            stmt.setString(2, maThamSo);                      // Mã tham số
                            stmt.setBigDecimal(3, new java.math.BigDecimal(giaTriNhap)); // Giá trị nhập (0-100)
                            stmt.registerOutParameter(4, Types.NVARCHAR);     // ThongBao
                            
                            stmt.execute();
                            
                            int returnCode = stmt.getInt(1);
                            String thongBao = stmt.getString(4);
                            
                            log.info("{}: return={}, message={}", maThamSo, returnCode, thongBao);
                            
                            if (returnCode == 0) {
                                successCount++;
                                messages.append("✓ ").append(maThamSo).append(": ").append(thongBao).append("\n");
                            } else {
                                errorCount++;
                                messages.append("✗ ").append(maThamSo).append(": ").append(thongBao).append("\n");
                            }
                        }
                    } catch (NumberFormatException e) {
                        errorCount++;
                        messages.append("✗ ").append(maThamSo).append(": Định dạng số không hợp lệ\n");
                        log.error("Invalid number format for {}: {}", maThamSo, valueStr);
                    } catch (SQLException e) {
                        errorCount++;
                        messages.append("✗ ").append(maThamSo).append(": Lỗi SQL - ").append(e.getMessage()).append("\n");
                        log.error("SQL error updating {}: {}", maThamSo, e.getMessage());
                    }
                }
                
                conn.commit();
                
                if (errorCount > 0) {
                    redirectAttributes.addFlashAttribute("errorMessage", 
                        String.format("Cập nhật: %d thành công, %d lỗi\n%s", 
                            successCount, errorCount, messages.toString()));
                } else if (successCount > 0) {
                    redirectAttributes.addFlashAttribute("successMessage", 
                        String.format("✅ Cập nhật thành công %d khuyến mãi!\n%s", 
                            successCount, messages.toString()));
                } else {
                    redirectAttributes.addFlashAttribute("errorMessage", 
                        "Không có khuyến mãi nào được cập nhật");
                }
                
            } catch (Exception e) {
                conn.rollback();
                log.error("Transaction failed, rolling back", e);
                redirectAttributes.addFlashAttribute("errorMessage", 
                    "Lỗi cập nhật khuyến mãi: " + e.getMessage());
            } finally {
                conn.setAutoCommit(true);
            }
            
        } catch (SQLException e) {
            log.error("Database connection error", e);
            redirectAttributes.addFlashAttribute("errorMessage", 
                "Lỗi kết nối database: " + e.getMessage());
        }
        
        return "redirect:/manager/settings";
    }

    private List<Map<String, Object>> getAllThamSo() throws SQLException {
        List<Map<String, Object>> result = new ArrayList<>();
        
        try (Connection conn = dataSource.getConnection();
             CallableStatement stmt = conn.prepareCall("{CALL sp_GetAllThamSo}")) {
            
            ResultSet rs = stmt.executeQuery();
            
            while (rs.next()) {
                Map<String, Object> row = new HashMap<>();
                String maThamSo = rs.getString("MaThamSo");
                row.put("maThamSo", maThamSo);
                row.put("tenThamSo", rs.getString("TenThamSo"));
                row.put("nhomThamSo", rs.getString("NhomThamSo"));
                row.put("donVi", rs.getString("DonVi"));
                
                double giaTriThamSo = rs.getDouble("GiaTriThamSo");
                
                // CHUYỂN ĐỔI % ĐỂ HIỂN THỊ
                // TS009, TS010, TS011: DB lưu 0.15 → hiển thị 15
                if (maThamSo.matches("TS009|TS010|TS011")) {
                    giaTriThamSo = giaTriThamSo * 100;
                }
                
                row.put("giaTriThamSo", giaTriThamSo);
                result.add(row);
            }
        }
        
        return result;
    }
}