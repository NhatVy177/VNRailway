package com.group10.vnrailway.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class PageResult<T> {
    private List<T> data;
    private long totalElements;
    private int totalPages;
    private int page;
    private int size;

    public PageResult(List<T> data, int totalElements, int totalPages, int page) {
        this.data = data;
        this.totalElements = totalElements;
        this.totalPages = totalPages;
        this.page = page;
    }

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
