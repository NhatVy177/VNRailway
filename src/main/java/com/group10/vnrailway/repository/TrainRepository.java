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
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Repository;

import com.group10.vnrailway.dto.PagedDbOutput;
import com.group10.vnrailway.dto.TripTrain;
import com.group10.vnrailway.entity.Train;


@Repository
public class TrainRepository {

    private final JdbcTemplate jdbcTemplate;
    private final SimpleJdbcCall getTrainsForTripCall;

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
}
