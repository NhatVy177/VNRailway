package com.group10.vnrailway.repository;

import com.group10.vnrailway.dto.MyBookingDTO;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.SqlOutParameter;
import org.springframework.jdbc.core.SqlParameter;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.SqlParameterSource;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Repository;

import java.sql.Types;
import java.util.List;
import java.util.Map;

@Repository
public class BookingRepository {

    private final JdbcTemplate jdbcTemplate;

    public BookingRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    /**
     * Gọi stored procedure usp_TaoDonDatVe_Online
     * 
     * INPUT Parameters:
     * - @MaChuyenTau    nchar(10)
     * - @MaGaDi         nchar(5)
     * - @MaGaDen        nchar(5)
     * - @MaKH_NguoiDat  nchar(10)
     * - @PhuongThucTT   nvarchar(12)
     * - @DanhSachVe     nvarchar(MAX) - JSON array
     * 
     * OUTPUT Parameters:
     * - @MaDonMoi       nchar(10) OUTPUT
     * - @ThongBao       nvarchar(200) OUTPUT
     * 
     * RETURN:
     * - Return code (0 = success, negative = error)
     * 
     * @return Map chứa: returnCode, maDonMoi, thongBao
     * @throws Exception nếu có lỗi database
     */
    public Map<String, Object> callTaoDonDatVe(
            String maChuyenTau,
            String maGaDi,
            String maGaDen,
            String maKHNguoiDat,
            String phuongThucTT,
            String danhSachVeJson
    ) throws Exception {
        
        // Sử dụng SimpleJdbcCall để xử lý stored procedure với OUTPUT parameters
        SimpleJdbcCall jdbcCall = new SimpleJdbcCall(jdbcTemplate)
                .withProcedureName("usp_TaoDonDatVe_Online")
                .declareParameters(
                        // INPUT parameters
                        new SqlParameter("MaChuyenTau", Types.NCHAR),
                        new SqlParameter("MaGaDi", Types.NCHAR),
                        new SqlParameter("MaGaDen", Types.NCHAR),
                        new SqlParameter("MaKH_NguoiDat", Types.NCHAR),
                        new SqlParameter("PhuongThucTT", Types.NVARCHAR),
                        new SqlParameter("DanhSachVe", Types.NVARCHAR),
                        
                        // OUTPUT parameters
                        new SqlOutParameter("MaDonMoi", Types.NCHAR),
                        new SqlOutParameter("ThongBao", Types.NVARCHAR)
                )
                .withoutProcedureColumnMetaDataAccess()
                .useInParameterNames(
                        "MaChuyenTau", "MaGaDi", "MaGaDen", 
                        "MaKH_NguoiDat", "PhuongThucTT", "DanhSachVe"
                );

        // Chuẩn bị parameters
        MapSqlParameterSource params = new MapSqlParameterSource()
                .addValue("MaChuyenTau", maChuyenTau)
                .addValue("MaGaDi", maGaDi)
                .addValue("MaGaDen", maGaDen)
                .addValue("MaKH_NguoiDat", maKHNguoiDat)
                .addValue("PhuongThucTT", phuongThucTT)
                .addValue("DanhSachVe", danhSachVeJson);

        // Execute stored procedure
        Map<String, Object> result = jdbcCall.execute(params);
        
        // Result chứa:
        // - #return_value (return code từ RETURN statement)
        // - MaDonMoi (OUTPUT)
        // - ThongBao (OUTPUT)
        
        return result;
    }

    /**
     * Gọi stored procedure usp_TaoDonDatVe_Offline cho nhân viên bán vé
     * 
     * INPUT Parameters:
     * - @MaChuyenTau        nchar(10)
     * - @MaGaDi             nchar(5)
     * - @MaGaDen            nchar(5)
     * - @MaNVBanVe          nchar(10)
     * - @PhuongThucTT       nvarchar(12)
     * - @DanhSachVe         nvarchar(MAX) - JSON array
     * - @NguoiDat_HoTen     nvarchar(50)
     * - @NguoiDat_CMND      nchar(12)
     * 
     * OUTPUT Parameters:
     * - @MaDonMoi       nchar(10) OUTPUT
     * - @ThongBao       nvarchar(200) OUTPUT
     * 
     * @return Map chứa: returnCode, MaDonMoi, ThongBao
     */
    public Map<String, Object> callTaoDonDatVeOffline(
            String maChuyenTau,
            String maGaDi,
            String maGaDen,
            String maNVBanVe,
            String phuongThucTT,
            String danhSachVeJson,
            String nguoiDatHoTen,
            String nguoiDatCMND
    ) throws Exception {
        
        SimpleJdbcCall jdbcCall = new SimpleJdbcCall(jdbcTemplate)
                .withProcedureName("usp_TaoDonDatVe_Offline")
                .declareParameters(
                        // INPUT parameters
                        new SqlParameter("MaChuyenTau", Types.NCHAR),
                        new SqlParameter("MaGaDi", Types.NCHAR),
                        new SqlParameter("MaGaDen", Types.NCHAR),
                        new SqlParameter("MaNVBanVe", Types.NCHAR),
                        new SqlParameter("PhuongThucTT", Types.NVARCHAR),
                        new SqlParameter("DanhSachVe", Types.NVARCHAR),
                        new SqlParameter("NguoiDat_HoTen", Types.NVARCHAR),
                        new SqlParameter("NguoiDat_CMND", Types.NCHAR),
                        
                        // OUTPUT parameters
                        new SqlOutParameter("MaDonMoi", Types.NCHAR),
                        new SqlOutParameter("ThongBao", Types.NVARCHAR)
                )
                .withoutProcedureColumnMetaDataAccess()
                .useInParameterNames(
                        "MaChuyenTau", "MaGaDi", "MaGaDen", 
                        "MaNVBanVe", "PhuongThucTT", "DanhSachVe",
                        "NguoiDat_HoTen", "NguoiDat_CMND"
                );

        // Chuẩn bị parameters
        MapSqlParameterSource params = new MapSqlParameterSource()
                .addValue("MaChuyenTau", maChuyenTau)
                .addValue("MaGaDi", maGaDi)
                .addValue("MaGaDen", maGaDen)
                .addValue("MaNVBanVe", maNVBanVe)
                .addValue("PhuongThucTT", phuongThucTT)
                .addValue("DanhSachVe", danhSachVeJson)
                .addValue("NguoiDat_HoTen", nguoiDatHoTen)
                .addValue("NguoiDat_CMND", nguoiDatCMND);

        // Execute stored procedure
        Map<String, Object> result = jdbcCall.execute(params);
        
        return result;
    }

    /**
     * Alternative simple method (không xử lý OUTPUT, chỉ execute)
     * Dùng khi không cần lấy maDon trả về
     * 
     * @deprecated Nên dùng callTaoDonDatVe() để lấy OUTPUT parameters
     */
    @Deprecated
    public void callTaoDonDatVeSimple(
            String maChuyenTau,
            String maGaDi,
            String maGaDen,
            String maKHNguoiDat,
            String phuongThucTT,
            String danhSachVeJson
    ) {
        String sql = """
            DECLARE @MaDon nchar(10), @Msg nvarchar(200);
            EXEC usp_TaoDonDatVe_Online 
                ?, ?, ?, ?, ?, ?,
                @MaDon OUTPUT, @Msg OUTPUT;
        """;

        jdbcTemplate.update(
                sql,
                maChuyenTau,
                maGaDi,
                maGaDen,
                maKHNguoiDat,
                phuongThucTT,
                danhSachVeJson
        );
    }
    
    /**
     * Lấy danh sách vé đã đặt của khách hàng
     * 
     * @param maKH - Mã khách hàng
     * @return Danh sách vé đã đặt
     */
    public List<MyBookingDTO> getDanhSachVeDaDat(String maKH) {
        String sql = """
            SELECT 
                ddv.MaDon as maDon,
                ddv.ThoiGianDatve as thoiGianDatVe,
                ddv.TongTien as tongTien,
                CASE 
                    WHEN v.TrangThai = N'Chưa thanh toán' THEN N'Chưa thanh toán'
                    WHEN v.TrangThai = N'Đã thanh toán' THEN N'Đã thanh toán'
                    WHEN v.TrangThai = N'Đã hủy' THEN N'Đã hủy'
                    ELSE N'Chưa thanh toán'
                END as trangThaiThanhToan,
                
                ct.MaChuyenTau as maChuyenTau,
                dt.TenTau as tenTau,
                ct.ThoiGianXuatPhat as thoiGianKhoiHanh,
                
                ddv.MaGaDi as maGaDi,
                gaDi.TenGa as tenGaDi,
                ddv.MaGaDen as maGaDen,
                gaDen.TenGa as tenGaDen,
                
                v.MaVe as maVe,
                v.MaToa as maToa,
                v.MaCho as maCho,
                CASE 
                    WHEN tt.LoaiToa = 'GH' THEN N'Ghế ngồi'
                    WHEN tt.LoaiToa = 'GI4' THEN N'Giường nằm 4'
                    WHEN tt.LoaiToa = 'GI6' THEN N'Giường nằm 6'
                    ELSE N'Không xác định'
                END as loaiCho,
                v.MaKH as tenHanhKhach,
                '' as cmnd,
                v.ThanhTien as giaVe,
                v.TrangThai as trangThaiVe
            FROM DON_DAT_VE ddv
            INNER JOIN CHI_TIET_VE v ON ddv.MaDon = v.MaDon
            INNER JOIN CHUYEN_TAU ct ON ddv.MaChuyenTau = ct.MaChuyenTau
            INNER JOIN DOAN_TAU dt ON ct.MaDoanTau = dt.MaDoanTau
            INNER JOIN GA gaDi ON ddv.MaGaDi = gaDi.MaGa
            INNER JOIN GA gaDen ON ddv.MaGaDen = gaDen.MaGa
            INNER JOIN TOA_TAU tt ON v.MaToa = tt.MaToa
            WHERE ddv.MaKH = ?
            ORDER BY ddv.ThoiGianDatve DESC, v.MaVe
        """;
        
        return jdbcTemplate.query(sql, (rs, rowNum) -> {
            MyBookingDTO dto = new MyBookingDTO();
            dto.setMaDon(rs.getString("maDon"));
            dto.setThoiGianDatVe(rs.getTimestamp("thoiGianDatVe").toLocalDateTime());
            dto.setTongTien(rs.getBigDecimal("tongTien"));
            dto.setTrangThaiThanhToan(rs.getString("trangThaiThanhToan"));
            
            dto.setMaChuyenTau(rs.getString("maChuyenTau"));
            dto.setTenTau(rs.getString("tenTau"));
            dto.setThoiGianKhoiHanh(rs.getTimestamp("thoiGianKhoiHanh").toLocalDateTime());
            
            dto.setMaGaDi(rs.getString("maGaDi"));
            dto.setTenGaDi(rs.getString("tenGaDi"));
            dto.setMaGaDen(rs.getString("maGaDen"));
            dto.setTenGaDen(rs.getString("tenGaDen"));
            
            dto.setMaVe(rs.getString("maVe"));
            dto.setMaToa(rs.getString("maToa"));
            dto.setMaCho(rs.getString("maCho"));
            dto.setLoaiCho(rs.getString("loaiCho"));
            dto.setTenHanhKhach(rs.getString("tenHanhKhach"));
            dto.setCmnd(rs.getString("cmnd"));
            dto.setGiaVe(rs.getBigDecimal("giaVe"));
            dto.setTrangThaiVe(rs.getString("trangThaiVe"));
            
            return dto;
        }, maKH);
    }
    
    /**
     * Lấy danh sách vé đã đặt theo số điện thoại hoặc CMND người đặt
     * Dành cho nhân viên bán vé tra cứu
     * 
     * @param soDienThoai - Số điện thoại người đặt (optional)
     * @param cmnd - CMND người đặt (optional)
     * @return Danh sách vé đã đặt
     */
    public List<MyBookingDTO> getDanhSachVeTheoSoDienThoaiHoacCMND(String soDienThoai, String cmnd) {
        SimpleJdbcCall jdbcCall = new SimpleJdbcCall(jdbcTemplate)
                .withProcedureName("usp_LayDanhSachVeTheoSoDienThoaiHoacCMND")
                .returningResultSet("result", (rs, rowNum) -> {
                    MyBookingDTO dto = new MyBookingDTO();
                    dto.setMaDon(rs.getString("MaDon"));
                    dto.setThoiGianDatVe(rs.getTimestamp("ThoiGianDatve").toLocalDateTime());
                    dto.setTongTien(rs.getBigDecimal("TongTien"));
                    dto.setTrangThaiThanhToan(rs.getString("TrangThaiThanhToan"));
                    
                    dto.setMaChuyenTau(rs.getString("MaChuyenTau"));
                    dto.setTenTau(rs.getString("TenTau"));
                    dto.setThoiGianKhoiHanh(rs.getTimestamp("ThoiGianKhoiHanh").toLocalDateTime());
                    
                    dto.setMaGaDi(rs.getString("MaGaDi"));
                    dto.setTenGaDi(rs.getString("TenGaDi"));
                    dto.setMaGaDen(rs.getString("MaGaDen"));
                    dto.setTenGaDen(rs.getString("TenGaDen"));
                    
                    dto.setMaVe(rs.getString("MaVe"));
                    dto.setMaToa(rs.getString("MaToa"));
                    dto.setMaCho(rs.getString("MaCho"));
                    dto.setLoaiCho(rs.getString("LoaiCho"));
                    dto.setTenHanhKhach(rs.getString("TenHanhKhach"));
                    
                    // Map CMNDHanhKhach từ SP
                    String cmndHanhKhach = rs.getString("CMNDHanhKhach");
                    dto.setCmnd(cmndHanhKhach != null ? cmndHanhKhach : "");
                    
                    dto.setGiaVe(rs.getBigDecimal("GiaVe"));
                    dto.setTrangThaiVe(rs.getString("TrangThaiVe"));
                    
                    // Thông tin người đặt
                    dto.setNguoiDatHoTen(rs.getString("NguoiDatHoTen"));
                    dto.setNguoiDatSDT(rs.getString("NguoiDatSDT"));
                    dto.setNguoiDatCMND(rs.getString("NguoiDatCMND"));
                    
                    return dto;
                });
        
        SqlParameterSource params = new MapSqlParameterSource()
                .addValue("SoDienThoai", soDienThoai)
                .addValue("CMND", cmnd);
        
        Map<String, Object> result = jdbcCall.execute(params);
        return (List<MyBookingDTO>) result.get("result");
    }

    /**
     * Cập nhật trạng thái thanh toán của tất cả vé trong đơn
     * Chỉ cập nhật nếu đơn thuộc về khách hàng và vé đang ở trạng thái "Chưa thanh toán"
     * 
     * @param maDon - Mã đơn đặt vé
     * @param maKH - Mã khách hàng (để xác thực quyền sở hữu)
     * @return Số lượng vé được cập nhật
     */
    public int capNhatTrangThaiThanhToan(String maDon, String maKH) {
        String sql;
        
        // Nếu maKH là null (nhân viên thanh toán), không check maKH
        if (maKH == null) {
            sql = """
                UPDATE CHI_TIET_VE
                SET TrangThai = N'Đã thanh toán',
                    ThoiGianXuatVe = GETDATE()
                WHERE MaDon = ?
                    AND TrangThai = N'Chưa thanh toán'
            """;
            return jdbcTemplate.update(sql, maDon);
        } else {
            sql = """
                UPDATE CHI_TIET_VE
                SET TrangThai = N'Đã thanh toán',
                    ThoiGianXuatVe = GETDATE()
                WHERE MaDon = ?
                    AND MaDon IN (SELECT MaDon FROM DON_DAT_VE WHERE MaKH = ?)
                    AND TrangThai = N'Chưa thanh toán'
            """;
            return jdbcTemplate.update(sql, maDon, maKH);
        }
    }

    /**
     * Cập nhật trạng thái thanh toán của từng vé riêng lẻ
     * Chỉ cập nhật nếu vé thuộc về khách hàng và đang ở trạng thái "Chưa thanh toán"
     * 
     * @param maVe - Mã vé cần thanh toán
     * @param maKH - Mã khách hàng (để xác thực quyền sở hữu)
     * @return Số lượng vé được cập nhật (0 hoặc 1)
     */
    public int capNhatTrangThaiThanhToanVe(String maVe, String maKH) {
        String sql = """
            UPDATE CHI_TIET_VE
            SET TrangThai = N'Đã thanh toán',
                ThoiGianXuatVe = GETDATE()
            WHERE MaVe = ?
                AND MaDon IN (SELECT MaDon FROM DON_DAT_VE WHERE MaKH = ?)
                AND TrangThai = N'Chưa thanh toán'
        """;
        
        return jdbcTemplate.update(sql, maVe, maKH);
    }
}