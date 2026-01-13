CREATE TYPE dbo.TVP_DanhSachGaTrongTuyen AS TABLE (
    MaGa NCHAR(5) NOT NULL,
    TrinhTu INT NOT NULL,
    TGDiChuyenGiuaCacGa TIME NOT NULL,
    KhoangCach DECIMAL(6,2) NOT NULL
);
GO