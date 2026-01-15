USE VNRAILWAY
GO

/* =========================================================
   SEQUENCE: SEQ_MA_DON_DAT_VE
   start_value = 21
========================================================= */
IF EXISTS (SELECT 1 FROM sys.sequences WHERE name = 'SEQ_MA_DON_DAT_VE')
    DROP SEQUENCE dbo.SEQ_MA_DON_DAT_VE;
GO

CREATE SEQUENCE dbo.SEQ_MA_DON_DAT_VE
    AS BIGINT
    START WITH 21
    INCREMENT BY 1
    NO CYCLE
    NO CACHE;
GO


/* =========================================================
   SEQUENCE: SEQ_MA_KHACH_HANG
   start_value = 10451
========================================================= */
IF EXISTS (SELECT 1 FROM sys.sequences WHERE name = 'SEQ_MA_KHACH_HANG')
    DROP SEQUENCE dbo.SEQ_MA_KHACH_HANG;
GO

CREATE SEQUENCE dbo.SEQ_MA_KHACH_HANG
    AS BIGINT
    START WITH 10451
    INCREMENT BY 1
    NO CYCLE
    NO CACHE;
GO


/* =========================================================
   SEQUENCE: SEQ_MA_VE
   start_value = 22
========================================================= */
IF EXISTS (SELECT 1 FROM sys.sequences WHERE name = 'SEQ_MA_VE')
    DROP SEQUENCE dbo.SEQ_MA_VE;
GO

CREATE SEQUENCE dbo.SEQ_MA_VE
    AS BIGINT
    START WITH 22
    INCREMENT BY 1
    NO CYCLE
    NO CACHE;
GO
