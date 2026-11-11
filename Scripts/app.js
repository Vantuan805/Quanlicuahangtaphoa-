/* ===================================================================
   HỆ THỐNG QUẢN LÝ CỬA HÀNG TẠP HÓA - CLIENT SCRIPTS (WEBFORMS)
   =================================================================== */

document.addEventListener('DOMContentLoaded', function () {
    // 1. Live Clock
    initLiveClock();

    // 2. Sidebar Toggle for Mobile
    initSidebar();

    // 3. F2 Shortcut for POS Cashier
    document.addEventListener('keydown', function (e) {
        if (e.key === 'F2') {
            e.preventDefault();
            window.location.href = 'POS.aspx';
        }
    });

    // 4. Quick POS Button in Topbar
    const btnQuickPos = document.getElementById('topbar-quick-pos');
    if (btnQuickPos) {
        btnQuickPos.addEventListener('click', function () {
            window.location.href = 'POS.aspx';
        });
    }

    // 5. Low stock alert button in Topbar
    const btnLowStock = document.getElementById('topbar-lowstock-btn');
    if (btnLowStock) {
        btnLowStock.addEventListener('click', function () {
            window.location.href = 'Inventory.aspx?status=low';
        });
    }
});

// Live Clock implementation
function initLiveClock() {
    const clockEl = document.getElementById('live-clock');
    if (!clockEl) return;

    function updateTime() {
        const now = new Date();
        const dateStr = now.toLocaleDateString('vi-VN', {
            weekday: 'short',
            day: '2-digit',
            month: '2-digit',
            year: 'numeric'
        });
        const timeStr = now.toLocaleTimeString('vi-VN', {
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit'
        });

        const dateSpan = clockEl.querySelector('.clock-date');
        const timeSpan = clockEl.querySelector('.clock-time');
        if (dateSpan) dateSpan.textContent = dateStr;
        if (timeSpan) timeSpan.textContent = timeStr;
    }

    updateTime();
    setInterval(updateTime, 1000);
}

// Sidebar toggle implementation
function initSidebar() {
    const toggleBtn = document.getElementById('sidebar-toggle');
    const sidebar = document.querySelector('.sidebar');
    if (toggleBtn && sidebar) {
        toggleBtn.addEventListener('click', function () {
            sidebar.classList.toggle('open');
        });
    }
}

// Modal Helpers - Fullscreen Fixed Overlay Centering & Scroll Handling
function openModal(modalId) {
    const modal = document.getElementById(modalId);
    if (!modal) return;

    // 1. Move modal directly under document.forms[0]
    // Keeps it inside ASP.NET form for postbacks, but breaks out of all parent layout containers!
    if (document.forms.length > 0 && modal.parentElement !== document.forms[0]) {
        document.forms[0].appendChild(modal);
    }

    // 2. Guaranteed inline fixed overlay styles (bypasses browser CSS cache issues)
    modal.style.position = 'fixed';
    modal.style.top = '0';
    modal.style.left = '0';
    modal.style.right = '0';
    modal.style.bottom = '0';
    modal.style.width = '100vw';
    modal.style.height = '100vh';
    modal.style.backgroundColor = 'rgba(15, 23, 42, 0.75)';
    modal.style.backdropFilter = 'blur(4px)';
    modal.style.webkitBackdropFilter = 'blur(4px)';
    modal.style.zIndex = '999999';
    modal.style.overflowX = 'hidden';
    modal.style.overflowY = 'auto';
    modal.style.padding = '30px 16px';
    modal.style.boxSizing = 'border-box';
    modal.style.display = 'flex';
    modal.style.alignItems = 'flex-start';
    modal.style.justifyContent = 'center';

    modal.classList.add('show', 'active');

    // 3. Style modal-dialog inside to ensure it is floating and centered
    const dialog = modal.querySelector('.modal-dialog');
    if (dialog) {
        dialog.style.position = 'relative';
        dialog.style.zIndex = '1000000';
        dialog.style.margin = '2rem auto';
        dialog.style.width = '100%';
        dialog.style.maxWidth = dialog.classList.contains('modal-lg') ? '800px' : (dialog.classList.contains('modal-sm') ? '420px' : '580px');
        dialog.style.backgroundColor = '#ffffff';
        dialog.style.borderRadius = '12px';
        dialog.style.boxShadow = '0 25px 50px -12px rgba(0, 0, 0, 0.35)';
        dialog.style.overflow = 'hidden';
    }

    // 4. Scroll modal to top so user sees the header and form fields right in viewport
    modal.scrollTop = 0;

    // 5. Prevent background body scrolling while modal is open
    document.body.style.overflow = 'hidden';
}

function closeModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
        modal.classList.remove('show', 'active');
        modal.style.display = 'none';
    }
    // Always restore normal body scrolling
    document.body.style.overflow = '';
}

// Global Handlers (Escape key, Click background to close, Safe scrolling)
document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape') {
        document.querySelectorAll('.modal').forEach(function (m) {
            if (m.style.display === 'flex' || m.style.display === 'block' || m.classList.contains('show') || m.classList.contains('active')) {
                closeModal(m.id);
            }
        });
    }
});

// Click outside modal dialog (on the dark backdrop) to close
document.addEventListener('click', function (e) {
    if (e.target && (e.target.classList.contains('modal') || e.target.classList.contains('modal-backdrop'))) {
        const modal = e.target.closest('.modal') || (e.target.classList.contains('modal') ? e.target : null);
        if (modal && modal.id) {
            closeModal(modal.id);
        }
    }
});

// Prevent number inputs from capturing mouse wheel and trapping page scroll
document.addEventListener('wheel', function (e) {
    if (document.activeElement && document.activeElement.type === 'number') {
        document.activeElement.blur();
    }
}, { passive: true });

// Smooth horizontal mouse wheel scroll for POS category chips
window.addEventListener('load', function () {
    document.body.style.overflow = '';
    const chips = document.querySelector('.pos-category-chips');
    if (chips) {
        chips.addEventListener('wheel', function (e) {
            if (e.deltaY !== 0) {
                e.preventDefault();
                this.scrollLeft += e.deltaY;
            }
        }, { passive: false });
    }
});

// Toast Notifications
function showToast(message, type = 'info') {
    let container = document.getElementById('toast-container');
    if (!container) {
        container = document.createElement('div');
        container.id = 'toast-container';
        container.className = 'toast-container';
        document.body.appendChild(container);
    }

    const toast = document.createElement('div');
    toast.className = `toast toast-${type}`;
    
    let icon = 'ℹ️';
    if (type === 'success') icon = '✅';
    if (type === 'warning') icon = '⚠️';
    if (type === 'danger' || type === 'error') icon = '❌';

    toast.innerHTML = `
        <span class="toast-icon">${icon}</span>
        <div class="toast-message">${message}</div>
    `;

    container.appendChild(toast);

    setTimeout(() => {
        toast.classList.add('show');
    }, 10);

    setTimeout(() => {
        toast.classList.remove('show');
        setTimeout(() => {
            if (toast.parentElement) toast.parentElement.removeChild(toast);
        }, 300);
    }, 4000);
}

// Print Receipt Helper
function printReceipt(elemId) {
    const printContent = document.getElementById(elemId);
    if (!printContent) return;
    window.print();
}
