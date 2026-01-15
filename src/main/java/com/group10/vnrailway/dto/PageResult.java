package com.group10.vnrailway.dto;

import lombok.Data;
import java.util.List;

@Data
public class PageResult<T> {
    private List<T> data;
    private int page;
    private int size;
    private long totalElements;
    private int totalPages;

    public void setSize(int size) {
        this.size = size;
        recalculateTotalPages();
    }

    public void setTotalElements(long totalElements) {
        this.totalElements = totalElements;
        recalculateTotalPages();
    }

    private void recalculateTotalPages() {
        if (size > 0) {
            this.totalPages = (int) Math.ceil((double) totalElements / size);
        } else {
            this.totalPages = 0;
        }
    }
}
