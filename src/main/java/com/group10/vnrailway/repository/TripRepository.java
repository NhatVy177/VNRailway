package com.group10.vnrailway.repository;

import com.group10.vnrailway.config.AppConfig;
import com.group10.vnrailway.db.ProcedureNameResolver;
import com.group10.vnrailway.dto.DbOutput;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.SqlOutParameter;
import org.springframework.jdbc.core.SqlParameter;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Repository;

import java.sql.Types;
import java.time.LocalDateTime;
import java.util.Map;

@Repository
public class TripRepository {

    private final SimpleJdbcCall createTripCall;
//    private SimpleJdbcCall updateCall;

    public TripRepository(JdbcTemplate jdbcTemplate, AppConfig config, ProcedureNameResolver resolver) {
        String spCreateTrip = "usp_ThemChuyenTau";

        if (config.getProblem() == 10) {
            spCreateTrip = resolver.resolve(spCreateTrip);
        }

        this.createTripCall = new SimpleJdbcCall(jdbcTemplate)
                .withProcedureName(spCreateTrip)
                .withReturnValue()
                .declareParameters(
                        new SqlParameter("MaTuyen", Types.NCHAR),
                        new SqlParameter("MaDoanTau", Types.NCHAR),
                        new SqlParameter("ThoiGianXuatPhat", Types.TIMESTAMP),
                        new SqlOutParameter("ThongBao", Types.NVARCHAR)
                );

//        this.updateCall = new SimpleJdbcCall(jdbcTemplate)
//                .withProcedureName("usp_CapNhatChuyenTau");
    }

    public DbOutput<Void> createTrip(String routeId, String trainId, LocalDateTime departureTime) {
        Map<String, Object> result = createTripCall.execute(Map.of(
                "MaTuyen", routeId,
                "MaDoanTau", trainId,
                "ThoiGianXuatPhat", departureTime
        ));

        int returnCode = result.get("RETURN_VALUE") != null ? (int) result.get("RETURN_VALUE") : -9000;
        String message = (String) result.get("ThongBao");

        return new DbOutput<>(returnCode, message, null);
    }
}
