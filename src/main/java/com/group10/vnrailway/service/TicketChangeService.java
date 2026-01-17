package com.group10.vnrailway.service;

import com.group10.vnrailway.dto.TicketChangeDTO;
import com.group10.vnrailway.repository.TicketChangeRepository;
import org.springframework.stereotype.Service;

import java.util.Map;

@Service
public class TicketChangeService {

    private final TicketChangeRepository ticketChangeRepository;

    public TicketChangeService(TicketChangeRepository ticketChangeRepository) {
        this.ticketChangeRepository = ticketChangeRepository;
    }

    /**
     * Lấy thông tin vé để đổi
     */
    public TicketChangeDTO layThongTinVeDeDoiVe(String maVe) {
        return ticketChangeRepository.layThongTinVeDeDoiVe(maVe);
    }

    /**
     * Đổi vé trong cùng chuyến (đổi chỗ)
     */
    public Map<String, Object> doiVeTrongCungChuyen(String maVeCu, String maGheMoi) {
        return ticketChangeRepository.doiVeTrongCungChuyen(maVeCu, maGheMoi);
    }

    /**
     * Đổi vé sang chuyến khác
     */
    public Map<String, Object> doiVeSangChuyenKhac(
            String maVeCu,
            String maChuyenTauMoi,
            String maGheMoi
    ) {
        return ticketChangeRepository.doiVeSangChuyenKhac(maVeCu, maChuyenTauMoi, maGheMoi);
    }
}
