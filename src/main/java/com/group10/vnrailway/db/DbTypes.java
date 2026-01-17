package com.group10.vnrailway.db;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum DbTypes {
    TVP_ROUTE_STATION("dbo.TVP_DanhSachGaTrongTuyen");

    private final String name;
}
