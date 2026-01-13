/**
 * booking-info.js
 * Logic: Parse JSON từ trip-detail, Render table, Custom modal, Calculate prices, Submit form
 * Compatible với CSS modules architecture
 */

// ============================================================================
// GLOBAL VARIABLES
// ============================================================================
let tickets = []; // Array chứa thông tin các vé
let currentEditIndex = -1; // Index của vé đang edit trong modal

// Đối tượng giảm giá (%) theo mã tham số
const DISCOUNT_RATES = {
    'TS009': 0.15,  // Người già
    'TS010': 0.12,  // Học sinh
    'TS011': 0.10,  // Sinh viên
    '': 0.00        // Không giảm giá
};

// Format tiền VNĐ
const formatCurrency = (amount) => new Intl.NumberFormat('vi-VN').format(amount);

// ============================================================================
// 1. KHỞI TẠO KHI LOAD TRANG
// ============================================================================
document.addEventListener('DOMContentLoaded', function() {
    // Chỉ chạy trên trang booking-info
    const bookingForm = document.getElementById('bookingForm');
    if (!bookingForm) return;
    
    // Parse JSON data từ hidden input
    const jsonInput = document.getElementById('danhSachChoJson');
    if (!jsonInput) {
        console.error('Không tìm thấy danhSachChoJson input');
        return;
    }
    
    const jsonData = jsonInput.value;
    
    try {
        const seatsData = JSON.parse(jsonData);
        
        // Khởi tạo tickets từ dữ liệu chọn ghế
        tickets = seatsData.map(seat => ({
            // Thông tin ghế (từ trip-detail)
            maToa: seat.maToa,
            maCho: seat.maCho,
            maCho_Display: seat.maCho_Display || seat.maCho,
            giaGoc: parseFloat(seat.giaGoc || 0),
            maThamSo: seat.maThamSo || '', // Mã tham số giá vé gốc
            
            // Thông tin hành khách (user sẽ nhập)
            passenger: null,
            
            // Đối tượng giảm giá (user chọn trong modal)
            doiTuong: '', // Mã tham số đối tượng (TS009-TS011 hoặc rỗng)
            discountRate: 0.00
        }));
        
        // Render bảng
        renderTable();
        
    } catch (error) {
        console.error('Lỗi parse JSON:', error);
        alert('Lỗi: Không thể đọc dữ liệu ghế đã chọn. Vui lòng quay lại trang trước.');
    }
    
    // Xử lý submit form
    handleFormSubmit();
    
    // Setup modal event listeners
    setupModalEventListeners();
    
    // Setup input validation
    setupInputValidation();
});

// ============================================================================
// 2. RENDER BẢNG DANH SÁCH VÉ
// ============================================================================
function renderTable() {
    const tbody = document.getElementById('ticketTableBody');
    if (!tbody) return;
    
    tbody.innerHTML = '';
    let total = 0;

    tickets.forEach((ticket, index) => {
        const discountAmount = ticket.giaGoc * ticket.discountRate;
        const finalPrice = ticket.giaGoc - discountAmount;
        total += finalPrice;

        // Hiển thị thông tin hành khách
        let passengerDisplay = '';
        if (ticket.passenger) {
            passengerDisplay = `
                <div class="passenger-name" title="${ticket.passenger.hoTen}">
                    ${ticket.passenger.hoTen}
                </div>
            `;
        } else {
            passengerDisplay = `<div class="passenger-input"></div>`;
        }

        const row = `
            <tr>
                <td class="fw-bold">${index + 1}</td>
                <td>
                    <div class="passenger-cell">
                        <div class="passenger-info"> 
                            ${passengerDisplay}
                        </div>
                        <button type="button" class="btn-update" onclick="openModal(${index})">
                            Cập nhật
                        </button>
                    </div>
                </td>
                <td>${ticket.maToa}</td>
                <td>${ticket.maCho_Display}</td>
                <td>${formatCurrency(ticket.giaGoc)}</td>
                <td>${formatCurrency(discountAmount)}</td>
                <td class="fw-bold">${formatCurrency(finalPrice)}</td>
            </tr>
        `;
        tbody.innerHTML += row;
    });

    const totalElement = document.getElementById('totalPrice');
    if (totalElement) {
        totalElement.innerText = formatCurrency(total);
    }
}

// ============================================================================
// 3. XỬ LÝ MODAL (CUSTOM - KHÔNG DÙNG BOOTSTRAP)
// ============================================================================
function openModal(index) {
    currentEditIndex = index;
    const ticket = tickets[index];
    const modal = document.getElementById('infoModal');
    
    if (!modal) return;

    // Reset form
    const form = document.getElementById('passengerForm');
    if (form) form.reset();

    // Nếu đã có dữ liệu, fill vào form
    if (ticket.passenger) {
        const modalName = document.getElementById('modalName');
        const modalCmnd = document.getElementById('modalCmnd');
        const modalPhone = document.getElementById('modalPhone');
        const modalDob = document.getElementById('modalDob');
        const modalAddress = document.getElementById('modalAddress');
        
        if (modalName) modalName.value = ticket.passenger.hoTen || '';
        if (modalCmnd) modalCmnd.value = ticket.passenger.cmnd || '';
        if (modalPhone) modalPhone.value = ticket.passenger.sdt || '';
        if (modalDob) modalDob.value = ticket.passenger.ngSinh || '';
        if (modalAddress) modalAddress.value = ticket.passenger.diaChi || '';
        
        // Set radio button đối tượng
        const radios = document.getElementsByName('discountType');
        radios.forEach(r => {
            if (r.value === ticket.doiTuong) r.checked = true;
        });
    } else {
        // Mặc định: Không giảm giá
        const typeNone = document.getElementById('typeNone');
        if (typeNone) typeNone.checked = true;
    }

    // Hiển thị modal
    modal.classList.add('active');
}

function closeModal() {
    const modal = document.getElementById('infoModal');
    if (modal) {
        modal.classList.remove('active');
    }
}

function savePassengerInfo() {
    // Validate bắt buộc
    const modalName = document.getElementById('modalName');
    const modalCmnd = document.getElementById('modalCmnd');
    
    const hoTen = modalName ? modalName.value.trim() : '';
    const cmnd = modalCmnd ? modalCmnd.value.trim() : '';
    
    if (!hoTen) {
        alert("Vui lòng nhập họ tên!");
        if (modalName) modalName.focus();
        return;
    }
    
    if (!cmnd) {
        alert("Vui lòng nhập CMND/CCCD!");
        if (modalCmnd) modalCmnd.focus();
        return;
    }
    
    // Validate CMND format (9-12 số)
    if (!/^\d{9,12}$/.test(cmnd)) {
        alert("CMND/CCCD không hợp lệ! Vui lòng nhập 9-12 chữ số.");
        if (modalCmnd) modalCmnd.focus();
        return;
    }
    
    // Validate SĐT nếu có
    const modalPhone = document.getElementById('modalPhone');
    const sdt = modalPhone ? modalPhone.value.trim() : '';
    if (sdt && !/^0\d{9}$/.test(sdt)) {
        alert("Số điện thoại không hợp lệ! Vui lòng nhập 10 số, bắt đầu bằng 0.");
        if (modalPhone) modalPhone.focus();
        return;
    }

    // Validate CMND không trùng với các vé khác
    for (let i = 0; i < tickets.length; i++) {
        if (i !== currentEditIndex && tickets[i].passenger && tickets[i].passenger.cmnd === cmnd) {
            alert(`CMND/CCCD "${cmnd}" đã được sử dụng cho vé ${i + 1}!\n\nQuy định: Mỗi CMND chỉ được đặt 1 ghế duy nhất trong cùng một đơn.`);
            if (modalCmnd) modalCmnd.focus();
            return;
        }
    }

    // Lấy đối tượng giảm giá đã chọn
    const radios = document.getElementsByName('discountType');
    let selectedDoiTuong = '';
    for (const radio of radios) {
        if (radio.checked) {
            selectedDoiTuong = radio.value;
            break;
        }
    }

    // Lấy các field optional
    const modalDob = document.getElementById('modalDob');
    const modalAddress = document.getElementById('modalAddress');
    
    const ngSinh = modalDob ? modalDob.value : '';
    const diaChi = modalAddress ? modalAddress.value.trim() : '';

    // Lưu thông tin hành khách
    tickets[currentEditIndex].passenger = {
        hoTen: hoTen,
        cmnd: cmnd,
        sdt: sdt || null,
        ngSinh: ngSinh || null,
        diaChi: diaChi || null
    };
    
    // Lưu đối tượng và tính discount rate
    tickets[currentEditIndex].doiTuong = selectedDoiTuong;
    tickets[currentEditIndex].discountRate = DISCOUNT_RATES[selectedDoiTuong] || 0.00;

    // Đóng modal và render lại bảng
    closeModal();
    renderTable();
}

// Setup modal event listeners
function setupModalEventListeners() {
    const modal = document.getElementById('infoModal');
    if (!modal) return;
    
    // Click outside modal to close
    modal.addEventListener('click', function(e) {
        if (e.target === modal) {
            closeModal();
        }
    });
    
    // ESC key to close
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') {
            closeModal();
        }
    });
}

// ============================================================================
// 4. XỬ LÝ SUBMIT FORM
// ============================================================================
function handleFormSubmit() {
    const form = document.getElementById('bookingForm');
    if (!form) return;
    
    form.addEventListener('submit', function(e) {
        e.preventDefault();
        
        // Validate: Tất cả vé phải có thông tin hành khách
        for (let i = 0; i < tickets.length; i++) {
            if (!tickets[i].passenger) {
                alert(`Vui lòng cập nhật thông tin hành khách cho vé ${i + 1}!`);
                return;
            }
        }
        
        // Validate: Phải chọn phương thức thanh toán
        const phuongThucTT = document.querySelector('input[name="phuongThucTT"]:checked');
        if (!phuongThucTT) {
            alert('Vui lòng chọn phương thức thanh toán!');
            return;
        }
        
        // Tạo hidden inputs cho từng vé
        // Format: danhSachVe[0].maToa, danhSachVe[0].maCho, ...
        tickets.forEach((ticket, index) => {
            const passenger = ticket.passenger;
            
            // Xác định maThamSo cuối cùng:
            // - Nếu có đối tượng giảm giá → dùng maThamSo đối tượng (TS009-TS011)
            // - Nếu không → dùng maThamSo giá vé gốc (GV001-GV012)
            const finalMaThamSo = ticket.doiTuong || ticket.maThamSo;

            // Tạo hidden inputs
            createHiddenInput(form, `danhSachVe[${index}].maToa`, ticket.maToa);
            createHiddenInput(form, `danhSachVe[${index}].maCho`, ticket.maCho);

            // Only send maThamSo if it has a value (NULL = no discount)
            if (finalMaThamSo) {
                createHiddenInput(form, `danhSachVe[${index}].maThamSo`, finalMaThamSo);
            }
            createHiddenInput(form, `danhSachVe[${index}].hoTen`, passenger.hoTen);
            createHiddenInput(form, `danhSachVe[${index}].cmnd`, passenger.cmnd);
            
            // Optional fields
            if (passenger.sdt) {
                createHiddenInput(form, `danhSachVe[${index}].sdt`, passenger.sdt);
            }
            if (passenger.ngSinh) {
                createHiddenInput(form, `danhSachVe[${index}].ngSinh`, passenger.ngSinh);
            }
            if (passenger.diaChi) {
                createHiddenInput(form, `danhSachVe[${index}].diaChi`, passenger.diaChi);
            }
        });
        
        // Confirm trước khi submit
        const total = tickets.reduce((sum, t) => {
            const discount = t.giaGoc * t.discountRate;
            return sum + (t.giaGoc - discount);
        }, 0);
        
        const confirmMsg = `Xác nhận đặt ${tickets.length} vé với tổng tiền ${formatCurrency(total)} VNĐ?`;
        
        if (confirm(confirmMsg)) {
            // Submit form
            form.submit();
        }
    });
}

// Helper: Tạo hidden input
function createHiddenInput(form, name, value) {
    const input = document.createElement('input');
    input.type = 'hidden';
    input.name = name;
    input.value = value;
    form.appendChild(input);
}

// ============================================================================
// 5. INPUT VALIDATION
// ============================================================================
function setupInputValidation() {
    // Validate CMND real-time
    const cmndInput = document.getElementById('modalCmnd');
    if (cmndInput) {
        cmndInput.addEventListener('input', function() {
            // Chỉ cho phép nhập số
            this.value = this.value.replace(/\D/g, '');
            
            // Giới hạn 12 ký tự
            if (this.value.length > 12) {
                this.value = this.value.slice(0, 12);
            }
        });
    }
    
    // Validate SĐT real-time
    const phoneInput = document.getElementById('modalPhone');
    if (phoneInput) {
        phoneInput.addEventListener('input', function() {
            // Chỉ cho phép nhập số
            this.value = this.value.replace(/\D/g, '');
            
            // Giới hạn 10 ký tự
            if (this.value.length > 10) {
                this.value = this.value.slice(0, 10);
            }
        });
    }
}

// ============================================================================
// 6. EXPOSE FUNCTIONS TO GLOBAL SCOPE (for onclick handlers)
// ============================================================================
window.openModal = openModal;
window.closeModal = closeModal;
window.savePassengerInfo = savePassengerInfo;