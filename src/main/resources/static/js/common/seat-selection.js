/**
 * Seat Selection Page JavaScript
 * Handles seat/berth selection and booking
 */

let selectedSeat = null;
let tripId, carriageId, departureStationId, arrivalStationId;

document.addEventListener('DOMContentLoaded', function() {
    console.log('Seat selection page loaded');
    
    // Initialize variables first
    if (!initializeVariables()) {
        console.error('Failed to initialize variables');
        showNotification('Lỗi: Không thể tải thông tin trang', 'error');
        return;
    }
    
    // Then initialize UI
    initializeSeatSelection();
    initializeButtons();
    initializeKeyboardNavigation();
    
    console.log('Seat selection initialized successfully');
});

/**
 * Initialize variables from hidden inputs
 * Returns false if any required variable is missing
 */
function initializeVariables() {
    const tripIdInput = document.getElementById('tripId');
    const carriageIdInput = document.getElementById('carriageId');
    const departureInput = document.getElementById('departureStationId');
    const arrivalInput = document.getElementById('arrivalStationId');
    
    // Check if all inputs exist
    if (!tripIdInput || !carriageIdInput || !departureInput || !arrivalInput) {
        console.error('Missing required hidden inputs');
        return false;
    }
    
    tripId = tripIdInput.value;
    carriageId = carriageIdInput.value;
    departureStationId = departureInput.value;
    arrivalStationId = arrivalInput.value;
    
    // Validate all values are present
    if (!tripId || !carriageId || !departureStationId || !arrivalStationId) {
        console.error('Some required values are empty:', {
            tripId, carriageId, departureStationId, arrivalStationId
        });
        return false;
    }
    
    console.log('Variables initialized:', { 
        tripId, carriageId, departureStationId, arrivalStationId 
    });
    
    return true;
}

/**
 * Initialize seat/berth click handlers
 */
function initializeSeatSelection() {
    const seatItems = document.querySelectorAll('.seat-item, .berth-item');
    
    console.log(`Found ${seatItems.length} selectable items`);
    
    if (seatItems.length === 0) {
        console.warn('No seats or berths found on page');
        showNotification('Không tìm thấy chỗ ngồi/giường', 'warning');
        return;
    }
    
    seatItems.forEach(item => {
        item.addEventListener('click', function() {
            handleSeatClick(this);
        });
        
        // Add keyboard accessibility
        item.addEventListener('keypress', function(e) {
            if (e.key === 'Enter' || e.key === ' ') {
                e.preventDefault();
                handleSeatClick(this);
            }
        });
    });
}

/**
 * Handle seat/berth click
 */
function handleSeatClick(item) {
    const available = item.dataset.available === 'true';
    
    // Check if seat is available
    if (!available) {
        showNotification('Chỗ này đã được đặt!', 'warning');
        return;
    }
    
    // Deselect previous seat
    if (selectedSeat) {
        selectedSeat.classList.remove('seat-selected', 'berth-selected');
    }
    
    // Select new seat
    const isSeat = item.classList.contains('seat-item');
    item.classList.add(isSeat ? 'seat-selected' : 'berth-selected');
    selectedSeat = item;
    
    // Get seat information
    const seatId = item.dataset.seatId || item.dataset.berthId;
    const price = item.dataset.price;
    
    // Update UI
    updateSelectionInfo(seatId, price);
    
    // Enable confirm button
    const confirmBtn = document.getElementById('confirmBtn');
    if (confirmBtn) {
        confirmBtn.disabled = false;
    }
    
    // Log selection
    console.log('Selected:', { seatId, price });
}

/**
 * Update selection information display
 */
function updateSelectionInfo(seatId, price) {
    // Update labels
    const seatLabel = document.getElementById('selectedSeatLabel');
    const priceLabel = document.getElementById('selectedSeatPrice');
    
    if (seatLabel) {
        seatLabel.textContent = seatId;
    }
    
    if (priceLabel) {
        const formattedPrice = new Intl.NumberFormat('vi-VN').format(price) + ' VNĐ';
        priceLabel.textContent = formattedPrice;
    }
}

/**
 * Initialize button handlers
 */
function initializeButtons() {
    // Cancel button
    const cancelBtn = document.getElementById('cancelBtn');
    if (cancelBtn) {
        cancelBtn.addEventListener('click', handleCancel);
    }
    
    // Confirm button
    const confirmBtn = document.getElementById('confirmBtn');
    if (confirmBtn) {
        confirmBtn.addEventListener('click', handleConfirm);
    }
}

/**
 * Handle cancel action
 */
function handleCancel() {
    if (selectedSeat) {
        selectedSeat.classList.remove('seat-selected', 'berth-selected');
        selectedSeat = null;
    }
    
    // Reset UI
    const seatLabel = document.getElementById('selectedSeatLabel');
    const priceLabel = document.getElementById('selectedSeatPrice');
    
    if (seatLabel) seatLabel.textContent = '--';
    if (priceLabel) priceLabel.textContent = '0 VNĐ';
    
    // Disable confirm button
    const confirmBtn = document.getElementById('confirmBtn');
    if (confirmBtn) {
        confirmBtn.disabled = true;
    }
}

/**
 * Handle confirm action - proceed to booking
 */
function handleConfirm() {
    if (!selectedSeat) {
        showNotification('Vui lòng chọn chỗ trước khi đặt vé!', 'warning');
        return;
    }
    
    const seatId = selectedSeat.dataset.seatId || selectedSeat.dataset.berthId;
    const price = selectedSeat.dataset.price;
    
    // Show loading
    showLoading();
    
    // Validate price by calling API
    validateAndProceed(seatId, price);
}

/**
 * Validate seat price and proceed to booking
 */
function validateAndProceed(seatId, price) {
    const url = `/trips/${tripId}/carriages/${carriageId}/price`;
    
    console.log('Validating price:', { url, seatId, departureStationId, arrivalStationId });
    
    fetch(url, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            seatId: seatId,
            departureStation: departureStationId,
            arrivalStation: arrivalStationId
        })
    })
    .then(response => {
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        return response.json();
    })
    .then(data => {
        hideLoading();
        
        if (data.success) {
            // Price validated, proceed to booking
            proceedToBooking(seatId, data.price);
        } else {
            showNotification('Không thể tính giá vé. Vui lòng thử lại!', 'error');
        }
    })
    .catch(error => {
        hideLoading();
        console.error('Error validating price:', error);
        showNotification('Lỗi kết nối. Vui lòng thử lại!', 'error');
    });
}

/**
 * Proceed to booking page
 */
function proceedToBooking(seatId, price) {
    const bookingUrl = `/booking/create?` +
        `tripId=${encodeURIComponent(tripId)}` +
        `&carriageId=${encodeURIComponent(carriageId)}` +
        `&seatId=${encodeURIComponent(seatId)}` +
        `&departureStation=${encodeURIComponent(departureStationId)}` +
        `&arrivalStation=${encodeURIComponent(arrivalStationId)}` +
        `&price=${encodeURIComponent(price)}`;
    
    console.log('Navigating to:', bookingUrl);
    
    // TODO: Replace with actual booking page when implemented
    // For now, show confirmation
    if (confirm(`Xác nhận đặt chỗ ${seatId} với giá ${new Intl.NumberFormat('vi-VN').format(price)} VNĐ?`)) {
        // window.location.href = bookingUrl;
        showNotification('Chức năng đặt vé đang được phát triển!', 'info');
    }
}

/**
 * Initialize keyboard navigation
 */
function initializeKeyboardNavigation() {
    document.addEventListener('keydown', function(e) {
        // ESC to cancel
        if (e.key === 'Escape') {
            handleCancel();
        }
        
        // Enter to confirm (if seat is selected)
        if (e.key === 'Enter' && selectedSeat && !e.target.classList.contains('seat-item') && !e.target.classList.contains('berth-item')) {
            handleConfirm();
        }
    });
}

/**
 * Show notification message
 */
function showNotification(message, type = 'info') {
    const colors = {
        info: '#2196F3',
        warning: '#ff9800',
        error: '#f44336',
        success: '#4CAF50'
    };
    
    const notification = document.createElement('div');
    notification.className = `notification notification-${type}`;
    notification.textContent = message;
    notification.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        padding: 16px 24px;
        background: ${colors[type] || colors.info};
        color: white;
        border-radius: 8px;
        box-shadow: 0 4px 12px rgba(0,0,0,0.3);
        z-index: 10000;
        animation: slideIn 0.3s ease-out;
        font-weight: 500;
        max-width: 300px;
    `;
    
    document.body.appendChild(notification);
    
    // Auto remove after 3 seconds
    setTimeout(() => {
        notification.style.animation = 'slideOut 0.3s ease-out';
        setTimeout(() => notification.remove(), 300);
    }, 3000);
}

/**
 * Show loading overlay
 */
function showLoading() {
    const overlay = document.createElement('div');
    overlay.className = 'loading-overlay';
    overlay.style.cssText = `
        position: fixed;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        background: rgba(0, 0, 0, 0.5);
        display: flex;
        align-items: center;
        justify-content: center;
        z-index: 9999;
    `;
    
    overlay.innerHTML = `
        <div class="loading-spinner" style="
            width: 50px;
            height: 50px;
            border: 4px solid #f3f3f3;
            border-top: 4px solid #854759;
            border-radius: 50%;
            animation: spin 1s linear infinite;
        "></div>
    `;
    
    document.body.appendChild(overlay);
}

/**
 * Hide loading overlay
 */
function hideLoading() {
    const overlay = document.querySelector('.loading-overlay');
    if (overlay) {
        overlay.remove();
    }
}

// Add CSS animations
const style = document.createElement('style');
style.textContent = `
    @keyframes slideIn {
        from {
            transform: translateX(400px);
            opacity: 0;
        }
        to {
            transform: translateX(0);
            opacity: 1;
        }
    }
    
    @keyframes slideOut {
        from {
            transform: translateX(0);
            opacity: 1;
        }
        to {
            transform: translateX(400px);
            opacity: 0;
        }
    }
    
    @keyframes spin {
        0% { transform: rotate(0deg); }
        100% { transform: rotate(360deg); }
    }
`;
document.head.appendChild(style);