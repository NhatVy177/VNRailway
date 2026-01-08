USE VNRAILWAY
GO
CREATE OR ALTER PROCEDURE usp_TraCuuChuyenTau
    @MaGaDi         NCHAR(5)  = NULL,
    @MaGaDen        NCHAR(5)  = NULL,
    @NgayDi         DATE      = NULL,
    @GioKhoiHanhTu  TIME      = NULL,
    @GioKhoiHanhDen TIME      = NULL,
    @LoaiTau        NCHAR(1)  = NULL,  -- 'S' = SE (Hạng sang), 'T' = Thường
    @LoaiCho        NCHAR(3)  = NULL,  -- 'GH' = Ghế, 'GI4' = Giường 4, 'GI6' = Giường 6
    @TrangThai      NCHAR(1)  = NULL   -- 'C' = Còn chỗ, NULL = Tất cả
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Bảng tạm lưu kết quả để lọc theo @TrangThai
    DECLARE @KetQua TABLE (
        MaChuyenTau         NCHAR(10),
        MaTuyen             NCHAR(4),
        TenTuyen            NVARCHAR(50),
        MaDoanTau           NCHAR(4),
        TenTau              NVARCHAR(50),
        LoaiTau             NCHAR(1),
        MaGaDi              NCHAR(5),
        TenGaDi             NVARCHAR(25),
        TrinhTuGaDi         INT,
        MaGaDen             NCHAR(5),
        TenGaDen            NVARCHAR(25),
        TrinhTuGaDen        INT,
        ThoiGianXuatPhat    DATETIME,
        ThoiGianKhoiHanh    DATETIME,
        ThoiGianDenDuKien   DATETIME,
        KhoangCach          DECIMAL(6,2),
        SoChoTrong          INT
    );
    
    -- Truy vấn dữ liệu chuyến tàu
    INSERT INTO @KetQua
    SELECT
        CT.MaChuyenTau,
        CT.MaTuyen,
        T.TenTuyen,
        CT.MaDoanTau,
        DT.TenTau,
        DT.LoaiTau,
        
        -- Thông tin ga đi
        GaDi.MaGa   AS MaGaDi,
        GaDi.TenGa  AS TenGaDi,
        TG_Di.TrinhTu AS TrinhTuGaDi,
        
        -- Thông tin ga đến
        GaDen.MaGa  AS MaGaDen,
        GaDen.TenGa AS TenGaDen,
        TG_Den.TrinhTu AS TrinhTuGaDen,
        
        -- Thời gian xuất phát tại ga đầu tuyến
        CT.ThoiGianXuatPhat,
        
        -- Thời gian khởi hành tại ga đi
        -- = ThoiGianXuatPhat + tổng TG di chuyển + thời gian dừng ga
        DATEADD(
            MINUTE,
            (
                -- Tổng thời gian di chuyển từ ga đầu đến ga đi
                SELECT SUM(DATEDIFF(MINUTE, '00:00:00', TG.TGDiChuyenGiuaCacGa))
                FROM TUYEN_GA TG
                WHERE TG.MaTuyen = CT.MaTuyen
                  AND TG.TrinhTu <= TG_Di.TrinhTu
            )
            +
            (
                -- Thời gian dừng ga: 5 phút mỗi ga (trừ ga đầu)
                CASE 
                    WHEN TG_Di.TrinhTu > 1 THEN (TG_Di.TrinhTu - 1) * 5
                    ELSE 0
                END
            ),
            CT.ThoiGianXuatPhat
        ) AS ThoiGianKhoiHanh,
        
        -- Thời gian đến ga đến (dự kiến)
        -- = ThoiGianXuatPhat + tổng TG di chuyển + thời gian dừng (trừ ga đến)
        DATEADD(
            MINUTE,
            (
                -- Tổng thời gian di chuyển tới ga đến
                SELECT SUM(DATEDIFF(MINUTE, '00:00:00', TG.TGDiChuyenGiuaCacGa))
                FROM TUYEN_GA TG
                WHERE TG.MaTuyen = CT.MaTuyen
                  AND TG.TrinhTu <= TG_Den.TrinhTu
            )
            +
            (
                -- Chỉ cộng thời gian dừng của các ga TRƯỚC ga đến
                CASE 
                    WHEN TG_Den.TrinhTu > 1 THEN (TG_Den.TrinhTu - 2) * 5
                    ELSE 0
                END
            ),
            CT.ThoiGianXuatPhat
        ) AS ThoiGianDenDuKien,
        
        -- Khoảng cách từ ga đi đến ga đến
        (
            SELECT SUM(TG.KhoangCach)
            FROM TUYEN_GA TG
            WHERE TG.MaTuyen = CT.MaTuyen
              AND TG.TrinhTu > TG_Di.TrinhTu
              AND TG.TrinhTu <= TG_Den.TrinhTu
        ) AS KhoangCach,
        
        -- Số chỗ trống (gọi function tính toán)
        dbo.fn_SoChoTrong_ChuyenTau(
            CT.MaChuyenTau,
            TG_Di.MaGa,
            TG_Den.MaGa,
            LEFT(@LoaiCho, 2)  -- Chỉ lấy 2 ký tự đầu: GH, GI
        ) AS SoChoTrong
        
    FROM CHUYEN_TAU CT
        INNER JOIN TUYEN T       ON CT.MaTuyen   = T.MaTuyen
        INNER JOIN DOAN_TAU DT   ON CT.MaDoanTau = DT.MaDoanTau
        
        -- Join với ga đi
        INNER JOIN TUYEN_GA TG_Di
            ON CT.MaTuyen = TG_Di.MaTuyen
           AND (@MaGaDi IS NULL OR TG_Di.MaGa = @MaGaDi)
        INNER JOIN GA GaDi
            ON TG_Di.MaGa = GaDi.MaGa
        
        -- Join với ga đến
        INNER JOIN TUYEN_GA TG_Den
            ON CT.MaTuyen = TG_Den.MaTuyen
           AND (@MaGaDen IS NULL OR TG_Den.MaGa = @MaGaDen)
        INNER JOIN GA GaDen
            ON TG_Den.MaGa = GaDen.MaGa
            
    WHERE
        -- Ga đi phải đứng trước ga đến trên cùng tuyến
        TG_Di.TrinhTu < TG_Den.TrinhTu
        
        -- Lọc ngày đi
        AND (@NgayDi IS NULL OR CAST(CT.ThoiGianXuatPhat AS DATE) = @NgayDi)
        
        -- Lọc giờ khởi hành tại ga đầu tuyến
        AND (@GioKhoiHanhTu IS NULL OR CAST(CT.ThoiGianXuatPhat AS TIME) >= @GioKhoiHanhTu)
        AND (@GioKhoiHanhDen IS NULL OR CAST(CT.ThoiGianXuatPhat AS TIME) <= @GioKhoiHanhDen)
        
        -- Lọc loại tàu
        AND (@LoaiTau IS NULL OR DT.LoaiTau = @LoaiTau)
        
        -- Chỉ lấy chuyến chưa khởi hành
        AND CT.ThoiGianXuatPhat > GETDATE();
    
    -- Trả về kết quả với điều kiện lọc @TrangThai
    SELECT 
        MaChuyenTau,
        MaTuyen,
        TenTuyen,
        MaDoanTau,
        TenTau,
        LoaiTau,
        MaGaDi,
        TenGaDi,
        TrinhTuGaDi,
        MaGaDen,
        TenGaDen,
        TrinhTuGaDen,
        ThoiGianXuatPhat,
        ThoiGianKhoiHanh,
        ThoiGianDenDuKien,
        KhoangCach,
        SoChoTrong
    FROM @KetQua
    WHERE 
        -- Lọc theo trạng thái
        (@TrangThai IS NULL OR (@TrangThai = 'C' AND SoChoTrong > 0))
    ORDER BY
        ThoiGianKhoiHanh ASC;
    
    RETURN 0;
END;
GO