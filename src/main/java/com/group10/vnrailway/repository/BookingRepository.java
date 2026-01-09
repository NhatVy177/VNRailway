package com.group10.vnrailway.repository;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.SqlOutParameter;
import org.springframework.jdbc.core.SqlParameter;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Repository;

import java.sql.Types;
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
}