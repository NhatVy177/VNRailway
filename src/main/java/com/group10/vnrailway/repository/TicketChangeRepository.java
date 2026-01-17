package com.group10.vnrailway.repository;

import com.group10.vnrailway.dto.TicketChangeDTO;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.SqlOutParameter;
import org.springframework.jdbc.core.SqlParameter;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Repository;

import java.sql.Types;
import java.util.Map;

@Repository
public class TicketChangeRepository {

    private final JdbcTemplate jdbcTemplate;

    public TicketChangeRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    /**
     * Lấy thông tin vé để đổi
     */
    public TicketChangeDTO layThongTinVeDeDoiVe(String maVe) {
        String sql = "EXEC sp_LayThongTinVeDeDoiVe ?";
        
        var results = jdbcTemplate.query(sql, (rs, rowNum) -> {
            TicketChangeDTO dto = new TicketChangeDTO();
            dto.setMaVe(rs.getString("MaVe") != null ? rs.getString("MaVe").trim() : null);
            dto.setMaDon(rs.getString("MaDon") != null ? rs.getString("MaDon").trim() : null);
            dto.setMaKH(rs.getString("MaKH") != null ? rs.getString("MaKH").trim() : null);
            dto.setTenKhachHang(rs.getString("TenKhachHang"));
            dto.setSdt(rs.getString("SDT"));
            dto.setMaGhe(rs.getString("MaGhe") != null ? rs.getString("MaGhe").trim() : null);
            dto.setLoaiCho(rs.getString("LoaiCho"));
            dto.setSoGhe(rs.getString("SoGhe") != null ? rs.getString("SoGhe").trim() : null);
            dto.setMaToa(rs.getString("MaToa") != null ? rs.getString("MaToa").trim() : null);
            dto.setTenToa(rs.getString("TenToa"));
            dto.setMaChuyenTau(rs.getString("MaChuyenTau") != null ? rs.getString("MaChuyenTau").trim() : null);
            dto.setMaGaDi(rs.getString("MaGaDi") != null ? rs.getString("MaGaDi").trim() : null);
            dto.setMaGaDen(rs.getString("MaGaDen") != null ? rs.getString("MaGaDen").trim() : null);
            dto.setThoiGianXuatPhat(rs.getTimestamp("ThoiGianXuatPhat").toLocalDateTime());
            dto.setThoiGianDen(rs.getTimestamp("ThoiGianDen").toLocalDateTime());
            dto.setTenTuyen(rs.getString("TenTuyen"));
            dto.setDoiTuong(rs.getString("DoiTuong"));
            dto.setGiaVeCu(rs.getBigDecimal("GiaVeCu"));
            dto.setTrangThai(rs.getString("TrangThai") != null ? rs.getString("TrangThai").trim() : null);
            dto.setPhiDoiVe(rs.getBigDecimal("PhiDoiVe"));
            dto.setThoiGianConLai(rs.getInt("ThoiGianConLai"));
            dto.setThoiGianToiThieuDoiVe(rs.getInt("ThoiGianToiThieuDoiVe"));
            
            // Đọc CoDuocDoiVe từ stored procedure
            int coDuocDoiVe = rs.getInt("CoDuocDoiVe");
            dto.setDuocDoiVe(coDuocDoiVe == 1);
            
            // Tạo thông báo lý do không đổi được
            if (coDuocDoiVe == 0) {
                String trangThai = rs.getString("TrangThai") != null ? rs.getString("TrangThai").trim() : "";
                int thoiGianConLai = rs.getInt("ThoiGianConLai");
                int thoiGianToiThieu = rs.getInt("ThoiGianToiThieuDoiVe");
                
                if (!"Đã thanh toán".equals(trangThai)) {
                    dto.setLyDoKhongDoiDuoc("Vé chưa được thanh toán hoặc đã bị hủy");
                } else if (thoiGianConLai < 0) {
                    dto.setLyDoKhongDoiDuoc("Chuyến tàu đã khởi hành");
                } else if (thoiGianConLai < thoiGianToiThieu) {
                    dto.setLyDoKhongDoiDuoc("Không đủ thời gian đổi vé (cần trước " + 
                        thoiGianToiThieu + " phút, còn lại " + thoiGianConLai + " phút)");
                } else {
                    dto.setLyDoKhongDoiDuoc("Không thể đổi vé");
                }
            }
            
            return dto;
        }, maVe);
        
        if (results.isEmpty()) {
            throw new RuntimeException("Không tìm thấy vé với mã: " + maVe);
        }
        return results.get(0);
    }

    /**
     * Đổi vé trong cùng chuyến (đổi chỗ)
     */
    public Map<String, Object> doiVeTrongCungChuyen(String maVeCu, String maGheMoi) {
        SimpleJdbcCall jdbcCall = new SimpleJdbcCall(jdbcTemplate)
                .withProcedureName("sp_DoiVeTrongCungChuyen")
                .declareParameters(
                        new SqlParameter("MaVeCu", Types.NVARCHAR),
                        new SqlParameter("MaGheMoi", Types.NVARCHAR),
                        new SqlOutParameter("MaVeMoi", Types.NVARCHAR),
                        new SqlOutParameter("ThongBao", Types.NVARCHAR)
                )
                .withoutProcedureColumnMetaDataAccess()
                .useInParameterNames("MaVeCu", "MaGheMoi");

        MapSqlParameterSource params = new MapSqlParameterSource()
                .addValue("MaVeCu", maVeCu)
                .addValue("MaGheMoi", maGheMoi);

        return jdbcCall.execute(params);
    }

    /**
     * Đổi vé sang chuyến khác
     */
    public Map<String, Object> doiVeSangChuyenKhac(
            String maVeCu, 
            String maChuyenTauMoi, 
            String maGheMoi
    ) {
        SimpleJdbcCall jdbcCall = new SimpleJdbcCall(jdbcTemplate)
                .withProcedureName("sp_DoiVeSangChuyenKhac")
                .declareParameters(
                        new SqlParameter("MaVeCu", Types.NVARCHAR),
                        new SqlParameter("MaChuyenTauMoi", Types.NVARCHAR),
                        new SqlParameter("MaGheMoi", Types.NVARCHAR),
                        new SqlOutParameter("MaDonMoi", Types.NVARCHAR),
                        new SqlOutParameter("MaVeMoi", Types.NVARCHAR),
                        new SqlOutParameter("ThongBao", Types.NVARCHAR)
                )
                .withoutProcedureColumnMetaDataAccess()
                .useInParameterNames("MaVeCu", "MaChuyenTauMoi", "MaGheMoi");

        MapSqlParameterSource params = new MapSqlParameterSource()
                .addValue("MaVeCu", maVeCu)
                .addValue("MaChuyenTauMoi", maChuyenTauMoi)
                .addValue("MaGheMoi", maGheMoi);

        return jdbcCall.execute(params);
    }
}
