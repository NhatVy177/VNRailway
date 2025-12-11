CREATE DATABASE VNRAILWAY
GO

USE VNRAILWAY
GO

-----------------------------------------------------------------------------------------------------
-- PHẦN 1: TẠO TẤT CẢ CÁC BẢNG 
-----------------------------------------------------------------------------------------------------

-- 1. Bảng NGUOI_DUNG
CREATE TABLE NGUOI_DUNG(
    MaNguoiDung nchar(10) PRIMARY KEY,
    HoTen nvarchar(50) NOT NULL,
    CMND nchar(12),
    NgSinh date CHECK (NgSinh < GETDATE()),
    DiaChi nvarchar(100),
    SDT nchar(10)  CHECK (SDT LIKE '0%' AND LEN(SDT) = 10),
    LoaiND nchar(2) NOT NULL CHECK (LoaiND IN ('KH', 'NV'))
);
CREATE UNIQUE INDEX IX_CMND ON NGUOI_DUNG(CMND) WHERE CMND IS NOT NULL;
CREATE UNIQUE INDEX IX_SDT ON NGUOI_DUNG(SDT) WHERE SDT IS NOT NULL;

-- 2. Bảng TAI_KHOAN
CREATE TABLE TAI_KHOAN (
    MaTaiKhoan nchar(10) PRIMARY KEY,
    MatKhau varchar(12) NOT NULL CHECK (LEN(MatKhau) BETWEEN 8 AND 12),
    NgayDK date NOT NULL CHECK (NgayDK <= GETDATE()),
    MaUser nchar(10) NOT NULL
);

-- 3. Bảng NHAN_VIEN
CREATE TABLE NHAN_VIEN (
    MaNV nchar(10) PRIMARY KEY,
    GioiTinh nvarchar(3) NOT NULL CHECK (GioiTinh IN (N'Nam', N'Nữ')),
    ChucVu nchar(2) NOT NULL
);

-- 4. Bảng CHINH_SACH_LUONG
CREATE TABLE CHINH_SACH_LUONG (
    MaLoaiNV nchar(2) PRIMARY KEY,
    LuongCoBan decimal(12, 2) NOT NULL,
    PhuCap decimal(12, 2) NOT NULL,
    ThuLaoChuyen decimal(12, 2) CHECK (ThuLaoChuyen >= 0),
    ThuLaoThayThe decimal(12, 2) CHECK (ThuLaoThayThe >= 0),
    PhatNghiPhep decimal(12, 2) CHECK (PhatNghiPhepPhatNghiPhep >= 0)
);

-- 5. Bảng DOAN_TAU
CREATE TABLE DOAN_TAU (
    MaDoanTau nchar(4) PRIMARY KEY,
    TenTau nvarchar(50),
    HangSX nvarchar(50) NOT NULL,
    NgVanHanh date NOT NULL CHECK (NgVanHanh <= GETDATE()),
    LoaiTau nchar(1) NOT NULL CHECK (LoaiTau IN ('S', 'T'))
);

-- 6. Bảng TOA_TAU
CREATE TABLE TOA_TAU (
    MaToa nchar(5) PRIMARY KEY,
    MaDoanTau nchar(4) NOT NULL,
    LoaiToa nchar(3) NOT NULL CHECK (LoaiToa IN ('GH', 'GI4', 'GI6')),
	STT int NOT NULL
);

-- 7. Bảng TUYEN
CREATE TABLE TUYEN (
    MaTuyen nchar(4) PRIMARY KEY,
    TenTuyen nvarchar(50) NOT NULL,
    MaNVQL nchar(10) NOT NULL
);

-- 8. Bảng TUYEN_DOANTAU
CREATE TABLE TUYEN_DOANTAU (
    MaTuyen nchar(4) NOT NULL,
    MaDoanTau nchar(4) NOT NULL,
    PRIMARY KEY (MaTuyen, MaDoanTau)
);

-- 9. Bảng GA
CREATE TABLE GA (
    MaGa nchar(5) PRIMARY KEY,
    TenGa nvarchar(25) NOT NULL
);

-- 10. Bảng TUYEN_GA
CREATE TABLE TUYEN_GA (
    MaTuyen nchar(4) NOT NULL,
    MaGa nchar(5) NOT NULL,
    TrinhTu int NOT NULL,
    TGDiChuyenGiuaCacGa time NOT NULL,
    KhoangCach decimal(6,2) NOT NULL,
    PRIMARY KEY (MaTuyen, MaGa)
);

-- 11. Bảng CHUYEN_TAU
CREATE TABLE CHUYEN_TAU (
    MaChuyenTau nchar(10) PRIMARY KEY,
    MaTuyen nchar(4) NOT NULL,
    MaDoanTau nchar(4) NOT NULL,
    ThoiGianXuatPhat datetime NOT NULL,
    ThoiGianDuKienDen datetime 
);

-- 12. Bảng PHANCONG_LAITAU
CREATE TABLE PHANCONG_LAITAU (
    MaNV nchar(10),
    MaChuyenTau nchar(10),
    VaiTro nvarchar(10) NOT NULL CHECK (VaiTro IN (N'Lái chính', N'Lái phụ')),
    TrangThai nvarchar(10) NOT NULL CHECK (TrangThai IN (N'Thực hiện', N'Thay thế', N'Nghỉ phép')),
    ThoiGianLamViec time,
    MaNVQL nchar(10) NOT NULL
	PRIMARY KEY(MaNV, MaChuyenTau)
);

-- 13. Bảng PHANCONG_TOA
CREATE TABLE PHANCONG_TOA (
    MaNV nchar(10),
    MaChuyenTau nchar(10),
    VaiTro nvarchar(20) NOT NULL CHECK (VaiTro IN (N'Trưởng toa', N'Nhân viên')),
    TrangThai nvarchar(20) NOT NULL CHECK (TrangThai IN (N'Thực hiện', N'Thay thế', N'Nghỉ phép')),
    MaNVQL nchar(10) NOT NULL,
    MaToa nchar(5) NOT NULL
	PRIMARY KEY(MaNV,MaChuyenTau)
);

-- 14. Bảng GHE
CREATE TABLE GHE (
    MaGhe nchar(6),
    MaToa nchar(5),
    Hang int,
    Cot int
	PRIMARY KEY(MaGhe, MaToa)
);

-- 15. Bảng GIUONG
CREATE TABLE GIUONG (
    MaGiuong nchar(6),
    MaToa nchar(5),
    Tang nvarchar(6) NOT NULL,
    SoPhong int NOT NULL,
    Phia nvarchar(8) NOT NULL
    PRIMARY KEY(MaGiuong,MaToa)
);

-- 16. Bảng KHACH_HANG
CREATE TABLE KHACH_HANG (
    MaKH nchar(10) PRIMARY KEY
);

-- 17. Bảng DON_DAT_VE
CREATE TABLE DON_DAT_VE (
    MaDon nchar(10) PRIMARY KEY,
    ThoiGianDatve datetime NOT NULL,
    TongTien decimal(12, 2),
    MaChuyenTau nchar(10) NOT NULL,
    MaGaDi nchar(5) NOT NULL,
    MaGaDen nchar(5) NOT NULL,
    MaNVBanVe nchar(10) NOT NULL,
    MaKH nchar(10) NOT NULL
);

-- 18. Bảng CHI_TIET_VE
CREATE TABLE CHI_TIET_VE (
    MaVe nchar(12) PRIMARY KEY,
    ThoiGianXuatVe datetime,
    TrangThai nvarchar(15) NOT NULL CHECK (TrangThai IN (N'Đã thanh toán', N'Đã hủy', N'Chưa thanh toán')),
    KhuyenMai decimal(12,2),
    PhuPhi decimal(12, 2),
    DoiTuong nchar(5),
    ThanhTien decimal(12, 2),
    PhuongThucTT nvarchar(12) NOT NULL CHECK (PhuongThucTT IN (N'Tiền mặt', N'Chuyển khoản')),
    MaToa nchar(5) NOT NULL,
    MaCho nchar(6) NOT NULL,
    MaDon nchar(10) NOT NULL,
    MaKH nchar(10) NOT NULL
);

-- 19. Bảng VI_TRI_CHO_TRONG
CREATE TABLE VI_TRI_CHO_TRONG (
    MaChoTrong nchar(6),
    MaToa nchar(5),
    LoaiCho nchar(2) NOT NULL CHECK (LoaiCho IN ('GH', 'GI'))
	PRIMARY KEY(MaChoTrong,MaToa)
);

-- 20. Bảng THAM_SO
CREATE TABLE THAM_SO (
    MaThamSo nchar(5) PRIMARY KEY,
    TenThamSo nvarchar(100) NOT NULL,
    GiaTriThamSo decimal(12, 2) NOT NULL
);

-- 21. Bảng HE_SO_VE
CREATE TABLE HE_SO_VE (
    MaHeSo nchar(5) PRIMARY KEY,
    NgayBD datetime NOT NULL,
    NgayKT datetime NOT NULL,
    HeSo decimal(2, 1) NOT NULL,
    GhiChu nvarchar(255)
);

-- 22. Bảng CHUYEN_GA 
CREATE TABLE CHUYEN_GA(
    MaChuyenTau nchar(10),
    MaGa        nchar(5),
    TrinhTu     int NOT NULL,
    ThoiGianDen time,
    ThoiGianDi  time
    PRIMARY KEY (MaChuyenTau, MaGa)
)
-----------------------------------------------------------------------------------------------------
-- PHẦN 2: THÊM RÀNG BUỘC KHÓA NGOẠI
-----------------------------------------------------------------------------------------------------
--TAI_KHOAN
ALTER TABLE TAI_KHOAN ADD
    CONSTRAINT FK1_TK_ND FOREIGN KEY (MaUser) REFERENCES NGUOI_DUNG(MaNguoiDung);

--NHAN_VIEN
ALTER TABLE NHAN_VIEN ADD
    CONSTRAINT FK1_NV_ND FOREIGN KEY (MaNV) REFERENCES NGUOI_DUNG(MaNguoiDung),
    CONSTRAINT FK2_NV_LUONG FOREIGN KEY (ChucVu) REFERENCES CHINH_SACH_LUONG(MaLoaiNV);

--TOA_TAU
ALTER TABLE TOA_TAU ADD
    CONSTRAINT FK1_TT_DOAN FOREIGN KEY (MaDoanTau) REFERENCES DOAN_TAU(MaDoanTau);

--TUYEN
ALTER TABLE TUYEN ADD
    CONSTRAINT FK1_TUYEN_NV FOREIGN KEY (MaNVQL) REFERENCES NHAN_VIEN(MaNV);

-- TUYEN_DOANTAU
ALTER TABLE TUYEN_DOANTAU ADD
	CONSTRAINT FK1_TDT_T FOREIGN KEY(MaTuyen) REFERENCES TUYEN(MaTuyen),
	CONSTRAINT FK2_TDT_DT FOREIGN KEY(MaDoanTau) REFERENCES DOAN_TAU(MaDoanTau);

--TUYEN_GA
ALTER TABLE TUYEN_GA ADD
	CONSTRAINT FK1_TG_T FOREIGN KEY(MaTuyen) REFERENCES TUYEN(MaTuyen),
	CONSTRAINT FK2_TG_G FOREIGN KEY(MaGa) REFERENCES GA(MaGa);

--CHUYEN_TAU
ALTER TABLE CHUYEN_TAU ADD
    CONSTRAINT FK1_CT_T FOREIGN KEY (MaTuyen) REFERENCES TUYEN(MaTuyen),
    CONSTRAINT FK2_CT_DT FOREIGN KEY (MaDoanTau) REFERENCES DOAN_TAU(MaDoanTau);
    
--CHUYEN_GA
ALTER TABLE CHUYEN_GA ADD
    CONSTRAINT FK1_CG_CT FOREIGN KEY(MaChuyenTau) REFERENCES CHUYEN_TAU(MaChuyenTau),
    CONSTRAINT FK2_CG_G FOREIGN KEY(MaGa) REFERENCES GA(MaGa);

--PHANCONG_LAITAU
ALTER TABLE PHANCONG_LAITAU ADD
    CONSTRAINT FK1_PCLT_NV FOREIGN KEY (MaNV) REFERENCES NHAN_VIEN(MaNV),
    CONSTRAINT FK2_PCLT_CHUYEN FOREIGN KEY (MaChuyenTau) REFERENCES CHUYEN_TAU(MaChuyenTau),
    CONSTRAINT FK3_PCLT_NVQL FOREIGN KEY (MaNVQL) REFERENCES NHAN_VIEN(MaNV);

-- PHANCONG_TOA
ALTER TABLE PHANCONG_TOA ADD
    CONSTRAINT FK1_PCT_NV FOREIGN KEY (MaNV) REFERENCES NHAN_VIEN(MaNV),
    CONSTRAINT FK2_PCT_CHUYEN FOREIGN KEY (MaChuyenTau) REFERENCES CHUYEN_TAU(MaChuyenTau),
    CONSTRAINT FK3_PCT_NVQL FOREIGN KEY (MaNVQL) REFERENCES NHAN_VIEN(MaNV),
    CONSTRAINT FK4_PCT_TOA FOREIGN KEY (MaToa) REFERENCES TOA_TAU(MaToa);

--VI_TRI_CHO_TRONG
ALTER TABLE VI_TRI_CHO_TRONG ADD
	CONSTRAINT FK1_VTCT_T FOREIGN KEY(MaToa) REFERENCES TOA_TAU(MaToa);

--GHE
ALTER TABLE GHE ADD
	CONSTRAINT FK1_G_VTCT FOREIGN KEY(MaGhe,MaToa) REFERENCES VI_TRI_CHO_TRONG(MaChoTrong,MaToa);

--GIUONG
ALTER TABLE GIUONG ADD
	CONSTRAINT FK1_GI_VTCT FOREIGN KEY(MaGiuong,MaToa) REFERENCES VI_TRI_CHO_TRONG(MaChoTrong,MaToa);

--DON_DAT_VE
ALTER TABLE DON_DAT_VE ADD
    CONSTRAINT FK1_DDV_CHUYEN FOREIGN KEY (MaChuyenTau,MaGaDi) REFERENCES CHUYEN_GA(MaChuyenTau,MaGa),
	CONSTRAINT FK2_DDV_GADEN FOREIGN KEY (MaChuyenTau,MaGaDen) REFERENCES CHUYEN_GA(MaChuyenTau,MaGa),
    CONSTRAINT FK3_DDV_NV FOREIGN KEY (MaNVBanVe) REFERENCES NHAN_VIEN(MaNV),
    CONSTRAINT FK4_DDV_KHACH FOREIGN KEY (MaKH) REFERENCES KHACH_HANG(MaKH);
    

--CHI_TIET_DAT_VE
ALTER TABLE CHI_TIET_VE ADD
    CONSTRAINT FK1_CTV_CHO FOREIGN KEY (MaCho, MaToa) REFERENCES VI_TRI_CHO_TRONG(MaChoTrong,MaToa),
    CONSTRAINT FK2_CTV_DON FOREIGN KEY (MaDon) REFERENCES DON_DAT_VE(MaDon),
    CONSTRAINT FK3_CTV_KHACH FOREIGN KEY (MaKH) REFERENCES KHACH_HANG(MaKH);




