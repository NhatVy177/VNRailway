/**
 * trip-detail.js
 * Logic: AJAX fetch carriages & seats/berths, Multiple seat selection, POST booking data
 * UI: Tooltip dynamic, Class switching
 */

let selectedSeats = []; // Array chứa các ghế/giường đã chọn (max 6)
const MAX_SEATS = 6;
let tripId, departureStationId, arrivalStationId, currentCarriageId, currentCarriageType;
const tooltip = document.getElementById('priceTooltip');

document.addEventListener('DOMContentLoaded', function() {
    initializeVariables();
});

function initializeVariables() {
    tripId = document.getElementById('tripId')?.value;
    departureStationId = document.getElementById('departureStationId')?.value;
    arrivalStationId = document.getElementById('arrivalStationId')?.value;
}

// ============================================================================
// 1. XỬ LÝ CLICK CHỌN TOA (UPDATE UI TRAIN SELECTOR)
// ============================================================================
function loadSeatSelection(carriageElement) {
    const carriageId = carriageElement.dataset.carriageId;
    const available = parseInt(carriageElement.dataset.available || '0');
    const carriageType = carriageElement.dataset.carriageType;
    const sequenceNumber = carriageElement.dataset.sequence;

    if (available === 0) {
        showNotification('Toa này đã hết chỗ!', 'warning');
        return;
    }

    // Active state cho CSS Shapes
    document.querySelectorAll('.car-item').forEach(item => item.classList.remove('active'));
    carriageElement.classList.add('active');

    // Update hidden inputs
    currentCarriageId = carriageId;
    currentCarriageType = carriageType;
    document.getElementById('currentCarriageId').value = carriageId;

    // Update Title
    const typeName = carriageType.includes('GH') ? 'Ghế ngồi mềm' : 
                     (carriageType.includes('4') ? 'Giường nằm khoang 4' : 'Giường nằm khoang 6');
    document.getElementById('seatSelectionTitle').textContent = `Toa ${sequenceNumber}: ${typeName}`;
    
    // Reset selection & Show loading
    handleCancel();
    document.getElementById('seatGrid').innerHTML = '<div class="loading-spinner"></div>';
    
    // Gọi AJAX
    loadSeatGrid(carriageId, carriageType);
}

// ============================================================================
// 2. LOAD SƠ ĐỒ GHẾ/GIƯỜNG (AJAX)
// ============================================================================
function loadSeatGrid(carriageId, carriageType) {
    // Xác định endpoint dựa trên loại toa
    const isSeatCarriage = carriageType.includes('GH') || carriageType.includes('Seat');
    const endpoint = isSeatCarriage ? 'seats' : 'berths';
    
    const url = `/trips/${tripId}/carriages/${carriageId}/${endpoint}?` +
                `departureStation=${departureStationId}&arrivalStation=${arrivalStationId}`;
    
    fetch(url)
        .then(response => {
            if (!response.ok) throw new Error('Network response was not ok');
            return response.text();
        })
        .then(html => {
            const container = document.getElementById('seatGrid');
            container.innerHTML = html;

            // Xóa hết class cũ để tránh lỗi layout
            container.className = ''; 

            // LOGIC QUAN TRỌNG:
            // Nếu là toa ghế (GH hoặc Seat) -> Thêm class layout-seat để CSS Grid hoạt động
            if (carriageType.includes('GH') || carriageType.includes('Seat')) {
                container.classList.add('layout-seat'); 
            } else {
                // Toa giường
                container.classList.add('sleeper-container');
            }

            initializeSeatInteraction();
        })
        .catch(error => {
            console.error('Error loading seats:', error);
            document.getElementById('seatGrid').innerHTML = 
                '<div style="text-align:center; color:#d35400; padding:20px;">Không thể tải sơ đồ ghế. Vui lòng thử lại.</div>';
        });
}

// ============================================================================
// 3. XỬ LÝ TƯƠNG TÁC GHẾ/GIƯỜNG (TOOLTIP & CLICK)
// ============================================================================
function initializeSeatInteraction() {
    // Selector lấy cả ghế (.seat-item) và giường (.bed-item, .berth-item)
    const items = document.querySelectorAll('.seat-item, .bed-item, .berth-item');

    items.forEach(item => {
        const priceRaw = item.dataset.price || 0;
        const priceText = new Intl.NumberFormat('vi-VN').format(priceRaw) + ' VNĐ';
        const label = item.dataset.seatCode || item.textContent.trim();
        const isBooked = item.classList.contains('item-booked') || item.dataset.available === 'false';

        // --- A. TOOLTIP LOGIC ---
        item.addEventListener('mouseenter', () => {
            const statusText = isBooked ? '(Đã đặt)' : '';
            tooltip.innerHTML = `<b>${label} ${statusText}</b><br>Giá: <span style="color:#d68f36; font-weight:bold">${priceText}</span>`;
            tooltip.style.display = 'block';
        });

        item.addEventListener('mousemove', (e) => {
            tooltip.style.left = (e.pageX + 15) + 'px';
            tooltip.style.top = (e.pageY + 15) + 'px';
        });

        item.addEventListener('mouseleave', () => {
            tooltip.style.display = 'none';
        });

        // --- B. CLICK LOGIC (MULTIPLE SELECTION) ---
        if (!isBooked) {
            item.addEventListener('click', function() {
                const seatId = this.dataset.seatId || this.dataset.berthId;
                const index = selectedSeats.findIndex(s => 
                    (s.dataset.seatId || s.dataset.berthId) === seatId
                );
                
                if (index > -1) {
                    // ☆ Bỏ chọn nếu đã chọn rồi
                    this.classList.remove('item-selected');
                    selectedSeats.splice(index, 1);
                } else {
                    // ☆ Thêm vào danh sách chọn (nếu chưa đủ 6)
                    if (selectedSeats.length >= MAX_SEATS) {
                        showNotification(`Chỉ được chọn tối đa ${MAX_SEATS} chỗ!`, 'warning');
                        return;
                    }
                    this.classList.add('item-selected');
                    selectedSeats.push(this);
                }
                
                // Update UI Action Panel
                updateSelectionDisplay();
            });
        } else {
            // Đảm bảo class booked được add nếu backend chỉ trả về attribute
            item.classList.add('item-booked');
        }
    });
}

// ============================================================================
// 4. CẬP NHẬT HIỂN THỊ GHẾ ĐÃ CHỌN
// ============================================================================
function updateSelectionDisplay() {
    const count = selectedSeats.length;
    const confirmBtn = document.getElementById('confirmBtn');
    
    if (count === 0) {
        document.getElementById('selectedSeatLabel').textContent = '--';
        document.getElementById('selectedSeatPrice').textContent = '0 VNĐ';
        confirmBtn.disabled = true;
    } else {
        // Hiển thị danh sách ghế đã chọn
        const labels = selectedSeats.map(s => s.textContent.trim()).join(', ');
        document.getElementById('selectedSeatLabel').textContent = 
            `${count} chỗ: ${labels}`;
        
        // Tính tổng giá
        const totalPrice = selectedSeats.reduce((sum, seat) => {
            return sum + parseFloat(seat.dataset.price || 0);
        }, 0);
        document.getElementById('selectedSeatPrice').textContent = 
            new Intl.NumberFormat('vi-VN').format(totalPrice) + ' VNĐ';
        
        confirmBtn.disabled = false;
    }
}

// ============================================================================
// 5. HỦY CHỌN GHẾ
// ============================================================================
function handleCancel() {
    // ☆ Clear tất cả ghế đã chọn
    selectedSeats.forEach(seat => {
        seat.classList.remove('item-selected');
    });
    selectedSeats = [];
    
    document.getElementById('selectedSeatLabel').textContent = '--';
    document.getElementById('selectedSeatPrice').textContent = '0 VNĐ';
    document.getElementById('confirmBtn').disabled = true;
}

// ============================================================================
// 6. XÁC NHẬN ĐẶT VÉ - POST SANG BOOKING-INFO
// ============================================================================
function handleConfirm() {
    if (selectedSeats.length === 0) return;
    
    // ☆ Thu thập thông tin tất cả ghế đã chọn
    const seatsData = selectedSeats.map(seat => {
        const seatId = seat.dataset.seatId || seat.dataset.berthId;
        const seatCode = seat.textContent.trim();
        const price = parseFloat(seat.dataset.price || 0);
        const paramCode = seat.dataset.paramCode || ''; // Mã tham số (GV001, GV002,...)
        
        return {
            maToa: currentCarriageId,
            maCho: seatId,
            maCho_Display: seatCode, // Để hiển thị
            giaGoc: price,
            maThamSo: paramCode,
            loaiToa: currentCarriageType
        };
    });
    
    const totalPrice = seatsData.reduce((sum, s) => sum + s.giaGoc, 0);
    const seatLabels = seatsData.map(s => s.maCho_Display).join(', ');
    
    // Confirm trước khi submit
    if(confirm(`Xác nhận đặt ${selectedSeats.length} chỗ: ${seatLabels}\nTổng giá: ${new Intl.NumberFormat('vi-VN').format(totalPrice)} VNĐ?`)){
        // Điền data vào form
        document.getElementById('formMaChuyenTau').value = tripId;
        document.getElementById('formMaGaDi').value = departureStationId;
        document.getElementById('formMaGaDen').value = arrivalStationId;
        document.getElementById('formDanhSachChoJson').value = JSON.stringify(seatsData);
        
        // Submit form POST
        document.getElementById('bookingForm').submit();
    }
}

// ============================================================================
// 7. SHOW NOTIFICATION
// ============================================================================
function showNotification(msg, type) {
    alert(msg); // Có thể thay bằng custom toast
}