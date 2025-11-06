// State management
const state = {
    userApps: [],
    convertedApps: [],
    selectedUserApps: new Set(),
    selectedConvertedApps: new Set(),
    currentTab: 'user'
};

// Initialize app
document.addEventListener('DOMContentLoaded', () => {
    initializeTabs();
    initializeButtons();
    initializeSearch();
    loadApps();
});

// Tab management
function initializeTabs() {
    const tabButtons = document.querySelectorAll('.tab-button');
    tabButtons.forEach(button => {
        button.addEventListener('click', () => {
            const tab = button.dataset.tab;
            switchTab(tab);
        });
    });
}

function switchTab(tab) {
    state.currentTab = tab;
    
    document.querySelectorAll('.tab-button').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.tab === tab);
    });
    
    document.querySelectorAll('.tab-content').forEach(content => {
        content.classList.remove('active');
    });
    
    if (tab === 'user') {
        document.getElementById('userAppsTab').classList.add('active');
    } else {
        document.getElementById('convertedAppsTab').classList.add('active');
    }
}

// Button initialization
function initializeButtons() {
    document.getElementById('selectAllUser').addEventListener('click', () => {
        toggleSelectAll('user');
    });
    
    document.getElementById('selectAllConverted').addEventListener('click', () => {
        toggleSelectAll('converted');
    });
    
    document.getElementById('convertSelected').addEventListener('click', () => {
        convertSelectedApps();
    });
    
    document.getElementById('restoreSelected').addEventListener('click', () => {
        restoreSelectedApps();
    });
}

// Search functionality
function initializeSearch() {
    const searchInput = document.getElementById('searchInput');
    searchInput.addEventListener('input', (e) => {
        const query = e.target.value.toLowerCase();
        filterApps(query);
    });
}

function filterApps(query) {
    const allAppItems = document.querySelectorAll('.app-item');
    
    allAppItems.forEach(item => {
        const nameEl = item.querySelector('.app-name');
        const pkgEl = item.querySelector('.app-package');
        
        if (!nameEl || !pkgEl) return;
        
        const name = nameEl.textContent.toLowerCase();
        const pkg = pkgEl.textContent.toLowerCase();
        
        if (query === '' || name.includes(query) || pkg.includes(query)) {
            item.style.display = 'flex';
        } else {
            item.style.display = 'none';
        }
    });
}

// Load apps from system
async function loadApps() {
    showLoading();
    
    try {
        await loadUserApps();
        await loadConvertedApps();
        
        renderUserApps();
        renderConvertedApps();
        updateStats();
    } catch (error) {
        showToast('Error loading apps');
        console.error(error);
    } finally {
        hideLoading();
    }
}

// Load user apps using API
async function loadUserApps() {
    try {
        const response = await fetch('/api.sh?action=list_user');
        const text = await response.text();
        console.log('User apps response:', text);
        const apps = JSON.parse(text);
        state.userApps = apps.sort((a, b) => a.label.localeCompare(b.label));
    } catch (error) {
        console.error('Error loading user apps:', error);
        state.userApps = [];
        showToast('Failed to load user apps');
    }
}

// Load converted apps using API
async function loadConvertedApps() {
    try {
        const response = await fetch('/api.sh?action=list_converted');
        const text = await response.text();
        console.log('Converted apps response:', text);
        state.convertedApps = JSON.parse(text);
    } catch (error) {
        console.error('Error loading converted apps:', error);
        state.convertedApps = [];
    }
}

// Render user apps list
function renderUserApps() {
    const container = document.getElementById('userAppsList');
    
    if (state.userApps.length === 0) {
        container.innerHTML = `
            <div class="empty-state">
                <div class="empty-state-icon">📱</div>
                <div class="empty-state-text">No user apps found</div>
            </div>
        `;
        return;
    }
    
    container.innerHTML = state.userApps.map(app => `
        <div class="app-item" data-package="${app.package}">
            <div class="app-checkbox"></div>
            <div class="app-icon">📦</div>
            <div class="app-info">
                <div class="app-name">${app.label}</div>
                <div class="app-package">${app.package}</div>
            </div>
        </div>
    `).join('');
    
    container.querySelectorAll('.app-item').forEach(item => {
        item.addEventListener('click', () => {
            const pkg = item.getAttribute('data-package');
            toggleAppSelection('user', pkg, item);
        });
    });
}

// Render converted apps list
function renderConvertedApps() {
    const container = document.getElementById('convertedAppsList');
    
    if (state.convertedApps.length === 0) {
        container.innerHTML = `
            <div class="empty-state">
                <div class="empty-state-icon">⚙️</div>
                <div class="empty-state-text">No converted apps yet</div>
            </div>
        `;
        return;
    }
    
    container.innerHTML = state.convertedApps.map(app => `
        <div class="app-item" data-package="${app.package}">
            <div class="app-checkbox"></div>
            <div class="app-icon">⚙️</div>
            <div class="app-info">
                <div class="app-name">${app.label}</div>
                <div class="app-package">${app.package}</div>
            </div>
        </div>
    `).join('');
    
    container.querySelectorAll('.app-item').forEach(item => {
        item.addEventListener('click', () => {
            const pkg = item.getAttribute('data-package');
            toggleAppSelection('converted', pkg, item);
        });
    });
}

// Toggle app selection
function toggleAppSelection(type, packageName, element) {
    const selectedSet = type === 'user' ? state.selectedUserApps : state.selectedConvertedApps;
    
    if (selectedSet.has(packageName)) {
        selectedSet.delete(packageName);
        element.classList.remove('selected');
    } else {
        selectedSet.add(packageName);
        element.classList.add('selected');
    }
}

// Select/Deselect all
function toggleSelectAll(type) {
    const selectedSet = type === 'user' ? state.selectedUserApps : state.selectedConvertedApps;
    const apps = type === 'user' ? state.userApps : state.convertedApps;
    const containerId = type === 'user' ? 'userAppsList' : 'convertedAppsList';
    const container = document.getElementById(containerId);
    const appItems = container.querySelectorAll('.app-item');
    
    const allSelected = selectedSet.size === apps.length;
    
    if (allSelected) {
        selectedSet.clear();
        appItems.forEach(item => item.classList.remove('selected'));
    } else {
        apps.forEach(app => selectedSet.add(app.package));
        appItems.forEach(item => item.classList.add('selected'));
    }
}

// Convert selected apps
async function convertSelectedApps() {
    if (state.selectedUserApps.size === 0) {
        showToast('Please select at least one app');
        return;
    }
    
    showLoading();
    
    let successCount = 0;
    let errorCount = 0;
    
    for (const packageName of state.selectedUserApps) {
        try {
            const response = await fetch('/api.sh?action=convert&package=' + encodeURIComponent(packageName));
            const result = await response.json();
            
            if (result.success) {
                successCount++;
            } else {
                errorCount++;
                console.error('Failed:', packageName, result.message);
            }
        } catch (error) {
            errorCount++;
            console.error('Error converting ' + packageName, error);
        }
    }
    
    state.selectedUserApps.clear();
    await loadApps();
    
    hideLoading();
    
    if (errorCount === 0) {
        showToast(successCount + ' app(s) converted! Reboot required.');
    } else {
        showToast('Converted ' + successCount + ', failed ' + errorCount);
    }
}

// Restore selected apps
async function restoreSelectedApps() {
    if (state.selectedConvertedApps.size === 0) {
        showToast('Please select at least one app');
        return;
    }
    
    showLoading();
    
    let successCount = 0;
    let errorCount = 0;
    
    for (const packageName of state.selectedConvertedApps) {
        try {
            const response = await fetch('/api.sh?action=restore&package=' + encodeURIComponent(packageName));
            const result = await response.json();
            
            if (result.success) {
                successCount++;
            } else {
                errorCount++;
                console.error('Failed:', packageName, result.message);
            }
        } catch (error) {
            errorCount++;
            console.error('Error restoring ' + packageName, error);
        }
    }
    
    state.selectedConvertedApps.clear();
    await loadApps();
    
    hideLoading();
    
    if (errorCount === 0) {
        showToast(successCount + ' app(s) restored! Reboot required.');
    } else {
        showToast('Restored ' + successCount + ', failed ' + errorCount);
    }
}

// Update statistics
function updateStats() {
    document.getElementById('userAppsCount').textContent = state.userApps.length;
    document.getElementById('convertedAppsCount').textContent = state.convertedApps.length;
}

// Show toast notification
function showToast(message) {
    const toast = document.getElementById('toast');
    const toastMessage = document.getElementById('toastMessage');
    
    toastMessage.textContent = message;
    toast.classList.add('show');
    
    setTimeout(() => {
        toast.classList.remove('show');
    }, 3000);
}

// Show loading overlay
function showLoading() {
    document.getElementById('loadingOverlay').classList.add('show');
}

// Hide loading overlay
function hideLoading() {
    document.getElementById('loadingOverlay').classList.remove('show');
}
