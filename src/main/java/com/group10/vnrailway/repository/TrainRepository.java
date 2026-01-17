package com.group10.vnrailway.repository;

import java.sql.Timestamp;
import java.sql.Types;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.jdbc.core.SqlOutParameter;
import org.springframework.jdbc.core.SqlParameter;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Repository;

import com.group10.vnrailway.dto.DbOutput;
import com.group10.vnrailway.dto.PagedDbOutput;
import com.group10.vnrailway.dto.TrainHistory;
import com.group10.vnrailway.dto.TrainList;
import com.group10.vnrailway.dto.TripTrain;
import com.group10.vnrailway.entity.Train;

import java.sql.Date;
import java.time.LocalDate;


@Repository
public class TrainRepository {

    private final JdbcTemplate jdbcTemplate;
    private final SimpleJdbcCall getTrainsForTripCall;
    private final SimpleJdbcCall getAllTrainsCall;
    private final SimpleJdbcCall createTrainCall;
    private final SimpleJdbcCall updateTrainCall;
    private final SimpleJdbcCall getTrainHistoryCall;

    private static final RowMapper<Train> TRAIN_ROW_MAPPER = (rs, rowNum) ->
            new Train(
                    rs.getString("MaDoanTau"),
                    rs.getString("TenTau"),
                    rs.getString("HangSX"),
                    rs.getDate("NgVanHanh").toLocalDate(),
                    rs.getString("LoaiTau")
            );

    private static final RowMapper<TripTrain> TRIP_TRAIN_ROW_MAPPER = (rs, rowNum) ->
            new TripTrain(
                    rs.getString("MaDoanTau"),
                    rs.getString("TenTau"),
                    rs.getString("HangSX"),
                    rs.getDate("NgVanHanh").toLocalDate(),
                    rs.getString("LoaiTau"),
                    rs.getBigDecimal("TongKmTrongTuan")
            );
    
    private static final RowMapper<TrainList> TRAIN_LIST_ROW_MAPPER = (rs, rowNum) -> {
        TrainList train = new TrainList();
        train.setMaDoanTau(rs.getString("MaDoanTau"));
        train.setTenTau(rs.getString("TenTau"));
        train.setHangSX(rs.getString("HangSX"));
        train.setNgVanHanh(rs.getDate("NgVanHanh").toLocalDate());
        train.setSoNamHoatDong(rs.getInt("SoNamHoatDong"));
        train.setLoaiTau(rs.getString("LoaiTau"));
        train.setTenLoaiTau(rs.getString("TenLoaiTau"));
        train.setSoToaTau(rs.getInt("SoToaTau"));
        train.setKmTrongTuan(rs.getBigDecimal("KmTrongTuan"));
        train.setKmToiThieu(rs.getBigDecimal("KmToiThieu"));
        train.setKmToiDa(rs.getBigDecimal("KmToiDa"));
        train.setTrangThaiKm(rs.getString("TrangThaiKm"));
        train.setMoTaTrangThai(rs.getString("MoTaTrangThai"));
        train.setSoChuyenTrongTuan(rs.getInt("SoChuyenTrongTuan"));
        train.setCacTuyenDangPhucVu(rs.getString("CacTuyenDangPhucVu"));
        return train;
    };

    private static final RowMapper<TrainHistory> TRAIN_HISTORY_ROW_MAPPER = (rs, rowNum) -> {
        TrainHistory history = new TrainHistory();
        history.setMaChuyenTau(rs.getString("MaChuyenTau"));
        history.setThoiGianXuatPhat(rs.getTimestamp("ThoiGianXuatPhat").toLocalDateTime());
        history.setMaTuyen(rs.getString("MaTuyen"));
        history.setTenTuyen(rs.getString("TenTuyen"));
        history.setKhoangCach(rs.getBigDecimal("KhoangCach"));
        history.setGaDi(rs.getString("GaDi"));
        history.setGaDen(rs.getString("GaDen"));
        history.setTrangThai(rs.getString("TrangThai"));
        history.setMoTaTrangThai(rs.getString("MoTaTrangThai"));
        history.setSoVeBan(rs.getInt("SoVeBan"));
        history.setSoLaiTau(rs.getInt("SoLaiTau"));
        history.setSoNhanVienPhucVu(rs.getInt("SoNhanVienPhucVu"));
        return history;
    };
    

    public TrainRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
        
        String spGetTrainListForTrip = "usp_LayDanhSachDoanTauChoChuyen";
      
        this.getTrainsForTripCall = new SimpleJdbcCall(jdbcTemplate)
                .withProcedureName(spGetTrainListForTrip)
                .withReturnValue()
                .declareParameters(
                        new SqlParameter("MaTuyen", Types.NCHAR),
                        new SqlParameter("ThoiDiem", Types.TIMESTAMP),
                        new SqlParameter("Trang", Types.INTEGER),
                        new SqlParameter("KichThuocTrang", Types.INTEGER),

                        new SqlOutParameter("SoKetQua", Types.INTEGER),
                        new SqlOutParameter("ThongBao", Types.NVARCHAR)
                )
                .returningResultSet(
                        "#result-set-1",
                        TRIP_TRAIN_ROW_MAPPER
                );
        
        // sp_GetDanhSachDoanTau
        this.getAllTrainsCall = new SimpleJdbcCall(jdbcTemplate)
                .withProcedureName("sp_GetDanhSachDoanTau")
                .withReturnValue()
                .declareParameters(
                        new SqlParameter("LoaiTau", Types.NCHAR),
                        new SqlParameter("TimKiem", Types.NVARCHAR),
                        new SqlParameter("Trang", Types.INTEGER),
                        new SqlParameter("KichThuocTrang", Types.INTEGER),
                        new SqlOutParameter("SoKetQua", Types.INTEGER),
                        new SqlOutParameter("ThongBao", Types.NVARCHAR)
                )
                .returningResultSet("#result-set-1", TRAIN_LIST_ROW_MAPPER);
        
        // sp_ThemDoanTau
        this.createTrainCall = new SimpleJdbcCall(jdbcTemplate)
                .withProcedureName("sp_ThemDoanTau")
                .withReturnValue()
                .declareParameters(
                        new SqlParameter("MaDoanTau", Types.NCHAR),
                        new SqlParameter("TenTau", Types.NVARCHAR),
                        new SqlParameter("HangSX", Types.NVARCHAR),
                        new SqlParameter("NgVanHanh", Types.DATE),
                        new SqlParameter("LoaiTau", Types.NCHAR),
                        new SqlOutParameter("ThongBao", Types.NVARCHAR)
                );
        
        // sp_CapNhatDoanTau
        this.updateTrainCall = new SimpleJdbcCall(jdbcTemplate)
                .withProcedureName("sp_CapNhatDoanTau")
                .withReturnValue()
                .declareParameters(
                        new SqlParameter("MaDoanTau", Types.NCHAR),
                        new SqlParameter("TenTau", Types.NVARCHAR),
                        new SqlParameter("HangSX", Types.NVARCHAR),
                        new SqlParameter("NgVanHanh", Types.DATE),
                        new SqlParameter("LoaiTau", Types.NCHAR),
                        new SqlOutParameter("ThongBao", Types.NVARCHAR)
                );
        
        // sp_GetLichSuChuyenTauDoanTau
        this.getTrainHistoryCall = new SimpleJdbcCall(jdbcTemplate)
                .withProcedureName("sp_GetLichSuChuyenTauDoanTau")
                .withReturnValue()
                .declareParameters(
                        new SqlParameter("MaDoanTau", Types.NCHAR),
                        new SqlParameter("TuNgay", Types.DATE),
                        new SqlParameter("DenNgay", Types.DATE),
                        new SqlParameter("Trang", Types.INTEGER),
                        new SqlParameter("KichThuocTrang", Types.INTEGER),
                        new SqlOutParameter("SoKetQua", Types.INTEGER),
                        new SqlOutParameter("ThongBao", Types.NVARCHAR)
                )
                .returningResultSet("#result-set-1", TRAIN_HISTORY_ROW_MAPPER);
      }

      
    public Optional<Train> getById(String id) {
        String sql = """
            SELECT * FROM DOAN_TAU
            WHERE MaDoanTau = ?
        """;

        return jdbcTemplate.query(sql, TRAIN_ROW_MAPPER, id)
                .stream()
                .findFirst();
    }


    public PagedDbOutput<TripTrain> getTrainsForTrip(
            String routeId,
            LocalDateTime time,
            int page,
            int pageSize
    ) {
        Map<String, Object> result = getTrainsForTripCall.execute(Map.of(
                "MaTuyen", routeId,
                "ThoiDiem", Timestamp.valueOf(time),
                "Trang", page,
                "KichThuocTrang", pageSize
        ));

        int returnCode = (int) result.getOrDefault("RETURN_VALUE", -9000);
        String message = (String) result.get("ThongBao");
        int totalItems = (int) result.getOrDefault("SoKetQua", 0);

        @SuppressWarnings("unchecked")
        List<TripTrain> data = (List<TripTrain>) result.get("#result-set-1");

        return new PagedDbOutput<>(returnCode, message, data, totalItems);
    }

    // ========== QUẢN LÝ ĐOÀN TÀU ==========
    
    /**
     * Lấy danh sách tất cả đoàn tàu với phân trang và filter
     */
    public PagedDbOutput<TrainList> getAllTrains(
            String loaiTau,
            String timKiem,
            int page,
            int pageSize
    ) {
        MapSqlParameterSource params = new MapSqlParameterSource()
                .addValue("LoaiTau", (loaiTau != null && !loaiTau.trim().isEmpty()) ? loaiTau : null, Types.NCHAR)
                .addValue("TimKiem", (timKiem != null && !timKiem.trim().isEmpty()) ? timKiem : null, Types.NVARCHAR)
                .addValue("Trang", page, Types.INTEGER)
                .addValue("KichThuocTrang", pageSize, Types.INTEGER);
        
        Map<String, Object> result = getAllTrainsCall.execute(params);

        int returnCode = (int) result.getOrDefault("RETURN_VALUE", -9000);
        String message = (String) result.get("ThongBao");
        int totalItems = (int) result.getOrDefault("SoKetQua", 0);

        @SuppressWarnings("unchecked")
        List<TrainList> data = (List<TrainList>) result.get("#result-set-1");

        return new PagedDbOutput<>(returnCode, message, data, totalItems);
    }

    /**
     * Thêm đoàn tàu mới
     */
    public DbOutput<Void> createTrain(
            String maDoanTau,
            String tenTau,
            String hangSX,
            LocalDate ngVanHanh,
            String loaiTau
    ) {
        Map<String, Object> params = Map.of(
                "MaDoanTau", maDoanTau,
                "TenTau", tenTau,
                "HangSX", hangSX,
                "NgVanHanh", Date.valueOf(ngVanHanh),
                "LoaiTau", loaiTau
        );
        
        Map<String, Object> result = createTrainCall.execute(params);

        int returnCode = result.get("RETURN_VALUE") != null ? (int) result.get("RETURN_VALUE") : -9000;
        String message = (String) result.get("ThongBao");

        return new DbOutput<>(returnCode, message, null);
    }

    /**
     * Cập nhật thông tin đoàn tàu
     */
    public DbOutput<Void> updateTrain(
            String maDoanTau,
            String tenTau,
            String hangSX,
            LocalDate ngVanHanh,
            String loaiTau
    ) {
        Map<String, Object> params = Map.of(
                "MaDoanTau", maDoanTau,
                "TenTau", tenTau != null ? tenTau : "",
                "HangSX", hangSX != null ? hangSX : "",
                "NgVanHanh", ngVanHanh != null ? Date.valueOf(ngVanHanh) : "",
                "LoaiTau", loaiTau != null ? loaiTau : ""
        );
        
        Map<String, Object> result = updateTrainCall.execute(params);

        int returnCode = result.get("RETURN_VALUE") != null ? (int) result.get("RETURN_VALUE") : -9000;
        String message = (String) result.get("ThongBao");

        return new DbOutput<>(returnCode, message, null);
    }

    /**
     * Lấy lịch sử chuyến tàu của đoàn tàu
     */
    public PagedDbOutput<TrainHistory> getTrainHistory(
            String maDoanTau,
            LocalDate tuNgay,
            LocalDate denNgay,
            int page,
            int pageSize
    ) {
        MapSqlParameterSource params = new MapSqlParameterSource()
                .addValue("MaDoanTau", maDoanTau, Types.NCHAR)
                .addValue("TuNgay", tuNgay != null ? Date.valueOf(tuNgay) : null, Types.DATE)
                .addValue("DenNgay", denNgay != null ? Date.valueOf(denNgay) : null, Types.DATE)
                .addValue("Trang", page, Types.INTEGER)
                .addValue("KichThuocTrang", pageSize, Types.INTEGER);
        
        Map<String, Object> result = getTrainHistoryCall.execute(params);

        int returnCode = (int) result.getOrDefault("RETURN_VALUE", -9000);
        String message = (String) result.get("ThongBao");
        int totalItems = (int) result.getOrDefault("SoKetQua", 0);

        @SuppressWarnings("unchecked")
        List<TrainHistory> data = (List<TrainHistory>) result.get("#result-set-1");

        return new PagedDbOutput<>(returnCode, message, data, totalItems);
    }
}
