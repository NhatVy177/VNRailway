package com.group10.vnrailway.repository;

import java.sql.Types;
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
import com.group10.vnrailway.dto.RouteWithTotalKm;
import com.group10.vnrailway.entity.Route;

@Repository
public class RouteRepository {

    private final JdbcTemplate jdbcTemplate;
    private final SimpleJdbcCall getAllRoutesCall;

    private static final RowMapper<Route> ROUTE_ROW_MAPPER = (rs, rowNum) ->
            new Route(
                    rs.getString("MaTuyen"),
                    rs.getString("TenTuyen"),
                    rs.getString("MaNVQL")
            );

    private static final RowMapper<RouteWithTotalKm> ROUTE_TOTAL_KM_ROW_MAPPER =
            (rs, rowNum) ->
                    new RouteWithTotalKm(
                            rs.getString("MaTuyen"),
                            rs.getString("TenTuyen"),
                            rs.getBigDecimal("TongSoKm")
                    );


    public RouteRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;

        String spName = "usp_LayDanhSachTuyen";

        this.getAllRoutesCall = new SimpleJdbcCall(jdbcTemplate)
                .withProcedureName(spName)
                .withReturnValue()
                .declareParameters(
                        new SqlParameter("Trang", Types.INTEGER),
                        new SqlParameter("KichThuocTrang", Types.INTEGER),

                        new SqlOutParameter("SoKetQua", Types.INTEGER),
                        new SqlOutParameter("ThongBao", Types.NVARCHAR)
                )
                .returningResultSet(
                        "#result-set-1",
                        ROUTE_TOTAL_KM_ROW_MAPPER
                );
    }


    public Optional<Route> getById(String id) {
        String sql = """
            SELECT * FROM TUYEN
            WHERE MaTuyen = ?
        """;

        return jdbcTemplate.query(sql, ROUTE_ROW_MAPPER, id)
                .stream()
                .findFirst();
    }


    public PagedDbOutput<RouteWithTotalKm> getAllRoutes(
            int page,
            int pageSize
    ) {
        Map<String, Object> result = getAllRoutesCall.execute(Map.of(
                "Trang", page,
                "KichThuocTrang", pageSize
        ));

        int returnCode =
                (int) result.getOrDefault("RETURN_VALUE", -9000);
        String message =
                (String) result.get("ThongBao");
        int totalItems =
                (int) result.getOrDefault("SoKetQua", 0);

        @SuppressWarnings("unchecked")
        List<RouteWithTotalKm> data =
                (List<RouteWithTotalKm>) result.get("#result-set-1");

        return new PagedDbOutput<>(returnCode, message, data, totalItems);
    }
}
