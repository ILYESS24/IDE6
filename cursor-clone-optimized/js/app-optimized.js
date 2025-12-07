// ==================== CONFIGURATION ====================
const DEFAULT_API_KEY = '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';
let apiKey = localStorage.getItem('apiKey') || DEFAULT_API_KEY;

const MODELS = [
    { id: 'anthropic/claude-3.5-sonnet', name: '⭐ Claude 3.5 Sonnet' },
    { id: 'anthropic/claude-3-opus', name: 'Claude 3 Opus' },
    { id: 'openai/gpt-4o', name: 'GPT-4o' },
    { id: 'openai/gpt-4-turbo', name: 'GPT-4 Turbo' },
    { id: 'google/gemini-pro-1.5', name: 'Gemini Pro 1.5' },
    { id: 'mistralai/mistral-large', name: 'Mistral Large' },
    { id: 'meta-llama/llama-3.1-405b-instruct', name: 'Llama 3.1 405B' },
    { id: 'deepseek/deepseek-coder', name: 'DeepSeek Coder' }
];

const FILE_ICONS = {
    'html': '🌐', 'htm': '🌐',
    'css': '🎨', 'scss': '🎨', 'sass': '🎨', 'less': '🎨',
    'js': '⚡', 'jsx': '⚛️', 'ts': '💠', 'tsx': '⚛️',
    'json': '📋', 'xml': '📄',
    'md': '📝', 'txt': '📄',
    'py': '🐍', 'rb': '💎', 'php': '🐘',
    'java': '☕', 'c': '🔧', 'cpp': '🔧', 'h': '📎',
    'go': '🐹', 'rs': '🦀', 'swift': '🍎',
    'sh': '🖥️', 'bash': '🖥️', 'zsh': '🖥️',
    'sql': '🗃️', 'graphql': '◼️',
    'yml': '⚙️', 'yaml': '⚙️', 'toml': '⚙️',
    'env': '🔐', 'gitignore': '📦',
    'svg': '🖼️', 'png': '🖼️', 'jpg': '🖼️', 'gif': '🖼️',
    'folder': '📁', 'folder-open': '📂'
};

// ==================== STATE ====================
let VFS = JSON.parse(localStorage.getItem('vfs')) || {
    'index.html': {
        type: 'file',
        content: '<!DOCTYPE html>\n<html>\n<head>\n  <title>My App</title>\n  <link rel="stylesheet" href="style.css">\n</head>\n<body>\n  <div class="container">\n    <h1>Hello World!</h1>\n    <p>Welcome to my app.</p>\n    <button id="btn">Click Me</button>\n  </div>\n  <script src="app.js"></script>\n</body>\n</html>',
        modified: false
    },
    'style.css': {
        type: 'file',
        content: '* {\n  margin: 0;\n  padding: 0;\n  box-sizing: border-box;\n}\n\nbody {\n  font-family: system-ui, sans-serif;\n  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);\n  min-height: 100vh;\n  display: flex;\n  justify-content: center;\n  align-items: center;\n}\n\n.container {\n  background: white;\n  padding: 40px;\n  border-radius: 16px;\n  box-shadow: 0 20px 60px rgba(0,0,0,0.3);\n  text-align: center;\n}\n\nh1 {\n  color: #333;\n  margin-bottom: 10px;\n}\n\np {\n  color: #666;\n  margin-bottom: 20px;\n}\n\nbutton {\n  background: #667eea;\n  color: white;\n  border: none;\n  padding: 12px 30px;\n  font-size: 16px;\n  border-radius: 8px;\n  cursor: pointer;\n  transition: transform 0.2s, box-shadow 0.2s;\n}\n\nbutton:hover {\n  transform: translateY(-2px);\n  box-shadow: 0 5px 20px rgba(102, 126, 234, 0.4);\n}',
        modified: false
    },
    'app.js': {
        type: 'file',
        content: '// Main application logic\nconst btn = document.getElementById("btn");\nlet clickCount = 0;\n\nbtn.addEventListener("click", () => {\n  clickCount++;\n  btn.textContent = `Clicked ${clickCount} times!`;\n  console.log("Button clicked:", clickCount);\n});\n\n// Log when page loads\nconsole.log("App initialized!");',
        modified: false
    },
    'README.md': {
        type: 'file',
        content: '# My Project\n\nA simple web application.\n\n## Features\n\n- Modern CSS styling\n- Interactive JavaScript\n- Clean HTML structure\n\n## Getting Started\n\n1. Open index.html in a browser\n2. Click the button\n3. Have fun!\n\n## License\n\nMIT',
        modified: false
    }
};

let editor = null;
let term = null;
let fitAddon = null;
let activeFile = null;
let openFiles = [];
let conversationHistory = [];
let cmdBuffer = '';
let cmdHistory = [];
let cmdHistoryIndex = -1;
let isStreaming = false;
let currentMentions = [];

// ==================== OPTIMIZED UTILITIES ====================
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        clearTimeout(timeout);
        timeout = setTimeout(() => func.apply(this, args), wait);
    };
}

function queueRender(type) {
    if (!renderQueue) renderQueue = new Set();
    if (!renderTimeout) renderTimeout = null;

    renderQueue.add(type);
    if (renderTimeout) clearTimeout(renderTimeout);
    renderTimeout = setTimeout(() => {
        renderQueue.forEach(renderType => {
            if (renderType === 'tree') renderTree();
            else if (renderType === 'tabs') renderTabs();
        });
        renderQueue.clear();
        renderTimeout = null;
    }, 0);
}

function getSortedFiles() {
    const currentKeys = Object.keys(VFS).sort().join(',');
    if (fileListCacheKey !== currentKeys) {
        fileListCacheKey = currentKeys;
        sortedFileList = Object.keys(VFS).sort((a, b) => {
            const aIsFolder = VFS[a].type === 'folder';
            const bIsFolder = VFS[b].type === 'folder';
            if (aIsFolder && !bIsFolder) return -1;
            if (!aIsFolder && bIsFolder) return 1;
            return a.localeCompare(b);
        });
    }
    return sortedFileList;
}

function invalidateFileCache() {
    fileListCacheKey = null;
    sortedFileList = null;
}

let renderQueue, renderTimeout, sortedFileList, fileListCacheKey;

// ==================== CORE FUNCTIONS ====================
function getFileIcon(name, isFolder = false) {
    if (isFolder) return FILE_ICONS['folder'];
    const ext = name.split('.').pop().toLowerCase();
    return FILE_ICONS[ext] || '📄';
}

function renderTree() {
    const tree = document.getElementById('fileTree');
    if (!tree) return;

    const files = getSortedFiles();
    tree.textContent = '';

    const fragment = document.createDocumentFragment();
    files.forEach(name => {
        const file = VFS[name];
        const isFolder = file.type === 'folder';
        const isActive = name === activeFile;

        const item = document.createElement('div');
        item.className = `tree-item ${isFolder ? 'folder' : ''} ${isActive ? 'active' : ''}`;
        item.dataset.name = name;

        const iconSpan = document.createElement('span');
        iconSpan.className = 'file-icon';
        iconSpan.textContent = getFileIcon(name, isFolder);
        item.appendChild(iconSpan);

        const nameSpan = document.createElement('span');
        nameSpan.textContent = name;
        item.appendChild(nameSpan);

        if (file.modified) {
            const modifiedSpan = document.createElement('span');
            modifiedSpan.className = 'modified';
            item.appendChild(modifiedSpan);
        }

        fragment.appendChild(item);
    });

    tree.appendChild(fragment);
    updateGitPanel();
}

function renderTabs() {
    const tabsBar = document.getElementById('tabsBar');
    if (!tabsBar) return;

    tabsBar.textContent = '';
    const fragment = document.createDocumentFragment();

    openFiles.forEach(f => {
        const file = VFS[f];
        const tab = document.createElement('div');
        tab.className = `tab ${f === activeFile ? 'active' : 'inactive'}`;
        tab.dataset.filename = f;

        const iconSpan = document.createElement('span');
        iconSpan.className = 'file-icon';
        iconSpan.style.fontSize = '12px';
        iconSpan.textContent = getFileIcon(f);
        tab.appendChild(iconSpan);

        const nameSpan = document.createElement('span');
        nameSpan.textContent = f;
        tab.appendChild(nameSpan);

        if (file?.modified) {
            const modifiedDot = document.createElement('span');
            modifiedDot.className = 'modified-dot';
            tab.appendChild(modifiedDot);
        }

        const closeIcon = document.createElement('i');
        closeIcon.className = 'codicon codicon-close tab-close';
        tab.appendChild(closeIcon);

        fragment.appendChild(tab);
    });

    tabsBar.appendChild(fragment);
}

// ==================== EVENT HANDLERS ====================
document.getElementById('fileTree')?.addEventListener('click', (e) => {
    const item = e.target.closest('.tree-item');
    if (!item) return;

    const fileName = item.dataset.name;
    const file = VFS[fileName];
    if (file && file.type !== 'folder') {
        openFile(fileName);
    }
});

document.getElementById('fileTree')?.addEventListener('contextmenu', (e) => {
    const item = e.target.closest('.tree-item');
    if (!item) return;

    e.preventDefault();
    const fileName = item.dataset.name;
    showContextMenu(e, fileName);
});

document.getElementById('tabsBar')?.addEventListener('click', (e) => {
    const tab = e.target.closest('.tab');
    if (!tab) return;

    const fileName = tab.dataset.filename;

    if (e.target.closest('.tab-close')) {
        e.stopPropagation();
        closeFile(fileName);
        return;
    }

    openFile(fileName);
});

// ==================== BASIC FUNCTIONS ====================
function toast(message, type = 'info') {
    const container = document.getElementById('toastContainer');
    if (!container) return;

    const t = document.createElement('div');
    t.className = `toast ${type}`;
    t.innerHTML = `<i class="codicon codicon-${type === 'success' ? 'check' : type === 'error' ? 'error' : 'info'}"></i> ${message}`;
    container.appendChild(t);
    setTimeout(() => t.remove(), 3000);
}

function setTheme(theme) {
    document.body.classList.toggle('theme-light', theme === 'light');
    localStorage.setItem('theme', theme);
    if (editor) {
        monaco.editor.setTheme(theme === 'light' ? 'vs' : 'vs-dark');
    }
}

function saveToLocalStorage() {
    localStorage.setItem('vfs', JSON.stringify(VFS));
}

// ==================== INITIALIZATION ====================
window.onload = () => {
    // Load theme
    const theme = localStorage.getItem('theme') || 'dark';
    setTheme(theme);

    // Initialize activity bar
    document.querySelectorAll('.act-item[data-view]').forEach(item => {
        item.onclick = () => activateView(item.dataset.view);
    });

    // Initialize resizers
    initResizers();

    // Render initial state
    renderTree();
    updateGitPanel();

    // Initialize terminal
    waitFor(() => typeof Terminal !== 'undefined', initTerminal);

    toast('Cursor Clone optimisé chargé!', 'success');
};

function waitFor(condition, callback, maxAttempts = 50) {
    let attempts = 0;
    const check = () => {
        if (condition()) callback();
        else if (++attempts < maxAttempts) setTimeout(check, 100);
    };
    check();
}

// Placeholder functions for compatibility
function activateView() {}
function initResizers() {}
function updateGitPanel() {}
function initTerminal() {}
function openFile() {}
function closeFile() {}
function showContextMenu() {}

// ==================== BASIC COMPATIBILITY ====================
// Add minimal implementations for essential functions
function initShortcuts() {
    document.addEventListener('keydown', e => {
        if (e.ctrlKey && e.key === 's') {
            e.preventDefault();
            if (activeFile) {
                VFS[activeFile].modified = false;
                saveToLocalStorage();
                renderTabs();
                toast('Fichier sauvegardé', 'success');
            }
        }
    });
}

// Initialize basic functionality
initShortcuts();
