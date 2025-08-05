// ===== NovelForge Sentinel Pro 管理员控制台脚本 =====

class AdminConsole {
    constructor() {
        this.currentLevel = 'level1';
        this.charts = {};
        this.mockData = this.generateMockData();
        
        this.init();
        this.bindEvents();
        this.initializeCharts();
        this.startRealTimeUpdates();
    }

    init() {
        // 初始化界面状态
        this.updateRoleDisplay();
        this.loadDashboardData();
    }

    bindEvents() {
        // 权限级别切换
        document.querySelectorAll('.permission-level').forEach(level => {
            level.addEventListener('click', () => {
                this.switchPermissionLevel(level.dataset.level);
            });
        });

        // 分析标签切换
        document.querySelectorAll('.tab').forEach(tab => {
            tab.addEventListener('click', () => {
                this.switchAnalysisTab(tab.dataset.tab);
            });
        });

        // 表格操作按钮
        document.querySelectorAll('.action-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                e.stopPropagation();
                this.handleAction(btn);
            });
        });

        // 卡密生成
        const generateBtn = document.querySelector('.generation-form .cyber-btn');
        if (generateBtn) {
            generateBtn.addEventListener('click', () => {
                this.generateCards();
            });
        }

        // 快捷操作
        document.querySelectorAll('.operation-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                this.handleQuickOperation(btn);
            });
        });

        // 时间选择器
        document.querySelectorAll('.time-selector, .report-selector').forEach(selector => {
            selector.addEventListener('change', () => {
                this.updateChartsData();
            });
        });
    }

    switchPermissionLevel(level) {
        // 更新权限级别选择器
        document.querySelectorAll('.permission-level').forEach(item => {
            item.classList.remove('active');
        });
        document.querySelector(`[data-level="${level}"]`).classList.add('active');

        // 切换界面
        document.querySelectorAll('.admin-interface').forEach(interface => {
            interface.classList.remove('active');
        });
        document.getElementById(`${level}-interface`).classList.add('active');

        this.currentLevel = level;
        this.updateRoleDisplay();
        this.loadLevelSpecificData(level);
    }

    updateRoleDisplay() {
        const roleElement = document.getElementById('current-role');
        const roleMap = {
            level1: '一级管理员',
            level2: '二级管理员',
            level3: '普通管理员'
        };
        
        if (roleElement) {
            roleElement.textContent = roleMap[this.currentLevel];
        }
    }

    loadLevelSpecificData(level) {
        switch (level) {
            case 'level1':
                this.updateMetricsOverview();
                this.updateSystemStats();
                this.updateSecurityAlerts();
                break;
            case 'level2':
                this.updateDepartmentStats();
                this.updatePermissionList();
                this.updateAuditLogs();
                break;
            case 'level3':
                this.updateCardStats();
                this.updateUserList();
                break;
        }
        
        // 重新初始化图表
        setTimeout(() => {
            this.initializeCharts();
        }, 100);
    }

    generateMockData() {
        return {
            metrics: {
                totalUsers: 12847,
                activeUsers: 8934,
                securityScore: 99.8,
                monthlyRevenue: 234000
            },
            userGrowth: {
                labels: ['1月', '2月', '3月', '4月', '5月', '6月'],
                data: [1200, 1900, 3000, 5000, 8000, 12847]
            },
            securityEvents: {
                labels: ['低风险', '中风险', '高风险'],
                data: [45, 12, 3]
            },
            departmentData: {
                managedUsers: 156,
                admins: 8,
                newThisMonth: 30
            },
            cardStats: {
                generated: 234,
                used: 189,
                available: 45
            }
        };
    }

    initializeCharts() {
        // 用户增长图表
        this.initUserGrowthChart();
        
        // 安全监控图表
        this.initSecurityChart();
        
        // 分析图表
        this.initAnalysisChart();
        
        // 部门图表
        this.initDepartmentChart();
        
        // 报表图表
        this.initReportChart();
    }

    initUserGrowthChart() {
        const ctx = document.getElementById('userGrowthChart');
        if (!ctx) return;

        if (this.charts.userGrowth) {
            this.charts.userGrowth.destroy();
        }

        this.charts.userGrowth = new Chart(ctx, {
            type: 'line',
            data: {
                labels: this.mockData.userGrowth.labels,
                datasets: [{
                    label: '用户增长',
                    data: this.mockData.userGrowth.data,
                    borderColor: '#64FFDA',
                    backgroundColor: 'rgba(100, 255, 218, 0.1)',
                    borderWidth: 2,
                    fill: true,
                    tension: 0.4
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        display: false
                    }
                },
                scales: {
                    x: {
                        grid: {
                            color: 'rgba(58, 80, 107, 0.3)'
                        },
                        ticks: {
                            color: '#8892B0'
                        }
                    },
                    y: {
                        grid: {
                            color: 'rgba(58, 80, 107, 0.3)'
                        },
                        ticks: {
                            color: '#8892B0'
                        }
                    }
                }
            }
        });
    }

    initSecurityChart() {
        const ctx = document.getElementById('securityChart');
        if (!ctx) return;

        if (this.charts.security) {
            this.charts.security.destroy();
        }

        this.charts.security = new Chart(ctx, {
            type: 'doughnut',
            data: {
                labels: this.mockData.securityEvents.labels,
                datasets: [{
                    data: this.mockData.securityEvents.data,
                    backgroundColor: [
                        '#00BFFF',
                        '#FFD700',
                        '#FF4D4D'
                    ],
                    borderWidth: 0
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        position: 'bottom',
                        labels: {
                            color: '#8892B0',
                            padding: 20
                        }
                    }
                }
            }
        });
    }

    initAnalysisChart() {
        const ctx = document.getElementById('analysisChart');
        if (!ctx) return;

        if (this.charts.analysis) {
            this.charts.analysis.destroy();
        }

        this.charts.analysis = new Chart(ctx, {
            type: 'bar',
            data: {
                labels: ['API调用', '响应时间', '成功率', '用户满意度'],
                datasets: [{
                    label: '性能指标',
                    data: [85, 92, 98, 88],
                    backgroundColor: [
                        'rgba(100, 255, 218, 0.3)',
                        'rgba(0, 191, 255, 0.3)',
                        'rgba(0, 255, 136, 0.3)',
                        'rgba(255, 215, 0, 0.3)'
                    ],
                    borderColor: [
                        '#64FFDA',
                        '#00BFFF',
                        '#00FF88',
                        '#FFD700'
                    ],
                    borderWidth: 2
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        display: false
                    }
                },
                scales: {
                    x: {
                        grid: {
                            color: 'rgba(58, 80, 107, 0.3)'
                        },
                        ticks: {
                            color: '#8892B0'
                        }
                    },
                    y: {
                        grid: {
                            color: 'rgba(58, 80, 107, 0.3)'
                        },
                        ticks: {
                            color: '#8892B0'
                        },
                        beginAtZero: true,
                        max: 100
                    }
                }
            }
        });
    }

    initDepartmentChart() {
        const ctx = document.getElementById('departmentChart');
        if (!ctx) return;

        if (this.charts.department) {
            this.charts.department.destroy();
        }

        this.charts.department = new Chart(ctx, {
            type: 'radar',
            data: {
                labels: ['用户管理', '权限分配', '数据报表', '操作审计', '安全监控'],
                datasets: [{
                    label: '部门能力',
                    data: [85, 92, 78, 88, 76],
                    borderColor: '#64FFDA',
                    backgroundColor: 'rgba(100, 255, 218, 0.2)',
                    borderWidth: 2
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        display: false
                    }
                },
                scales: {
                    r: {
                        grid: {
                            color: 'rgba(58, 80, 107, 0.3)'
                        },
                        pointLabels: {
                            color: '#8892B0'
                        },
                        ticks: {
                            color: '#8892B0',
                            beginAtZero: true
                        }
                    }
                }
            }
        });
    }

    initReportChart() {
        const ctx = document.getElementById('reportChart');
        if (!ctx) return;

        if (this.charts.report) {
            this.charts.report.destroy();
        }

        this.charts.report = new Chart(ctx, {
            type: 'line',
            data: {
                labels: ['周一', '周二', '周三', '周四', '周五', '周六', '周日'],
                datasets: [{
                    label: '活跃度',
                    data: [65, 78, 82, 75, 89, 56, 42],
                    borderColor: '#00BFFF',
                    backgroundColor: 'rgba(0, 191, 255, 0.1)',
                    borderWidth: 2,
                    fill: true,
                    tension: 0.4
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        display: false
                    }
                },
                scales: {
                    x: {
                        grid: {
                            color: 'rgba(58, 80, 107, 0.3)'
                        },
                        ticks: {
                            color: '#8892B0'
                        }
                    },
                    y: {
                        grid: {
                            color: 'rgba(58, 80, 107, 0.3)'
                        },
                        ticks: {
                            color: '#8892B0'
                        }
                    }
                }
            }
        });
    }

    updateMetricsOverview() {
        // 更新关键指标显示
        const metrics = document.querySelectorAll('.metric-value');
        metrics[0].textContent = this.mockData.metrics.totalUsers.toLocaleString();
        metrics[1].textContent = this.mockData.metrics.activeUsers.toLocaleString();
        metrics[2].textContent = this.mockData.metrics.securityScore + '%';
        metrics[3].textContent = '¥' + (this.mockData.metrics.monthlyRevenue / 1000) + 'K';
    }

    updateSystemStats() {
        // 更新系统统计信息
        const statFills = document.querySelectorAll('.system-stat .stat-fill');
        const statValues = document.querySelectorAll('.system-stat .stat-value');
        
        // 模拟动态更新
        setInterval(() => {
            const cpuUsage = Math.random() * 30 + 30; // 30-60%
            const memoryUsage = Math.random() * 40 + 40; // 40-80%
            const storageUsage = Math.random() * 20 + 10; // 10-30%
            
            if (statFills[0]) {
                statFills[0].style.width = cpuUsage + '%';
                statValues[0].textContent = Math.round(cpuUsage) + '%';
            }
            if (statFills[1]) {
                statFills[1].style.width = memoryUsage + '%';
                statValues[1].textContent = Math.round(memoryUsage) + '%';
            }
            if (statFills[2]) {
                statFills[2].style.width = storageUsage + '%';
                statValues[2].textContent = Math.round(storageUsage) + '%';
            }
        }, 5000);
    }

    updateSecurityAlerts() {
        // 安全警报已在HTML中定义，这里可以添加动态更新逻辑
        console.log('更新安全警报...');
    }

    updateDepartmentStats() {
        // 更新部门统计
        const deptNumbers = document.querySelectorAll('.dept-number');
        if (deptNumbers.length >= 3) {
            deptNumbers[0].textContent = this.mockData.departmentData.managedUsers;
            deptNumbers[1].textContent = this.mockData.departmentData.admins;
            deptNumbers[2].textContent = this.mockData.departmentData.newThisMonth;
        }
    }

    updatePermissionList() {
        // 权限列表已在HTML中定义
        console.log('更新权限列表...');
    }

    updateAuditLogs() {
        // 审计日志已在HTML中定义
        console.log('更新审计日志...');
    }

    updateCardStats() {
        // 更新卡密统计
        const cardNumbers = document.querySelectorAll('.card-stat .stat-number');
        if (cardNumbers.length >= 3) {
            cardNumbers[0].textContent = this.mockData.cardStats.generated;
            cardNumbers[1].textContent = this.mockData.cardStats.used;
            cardNumbers[2].textContent = this.mockData.cardStats.available;
        }
    }

    updateUserList() {
        // 用户列表已在HTML中定义
        console.log('更新用户列表...');
    }

    switchAnalysisTab(tabName) {
        // 切换分析标签
        document.querySelectorAll('.tab').forEach(tab => {
            tab.classList.remove('active');
        });
        document.querySelector(`[data-tab="${tabName}"]`).classList.add('active');

        // 更新分析图表数据
        this.updateAnalysisChart(tabName);
    }

    updateAnalysisChart(tabName) {
        if (!this.charts.analysis) return;

        const dataMap = {
            usage: {
                labels: ['API调用', '响应时间', '成功率', '用户满意度'],
                data: [85, 92, 98, 88]
            },
            performance: {
                labels: ['延迟', '吞吐量', '错误率', '可用性'],
                data: [78, 95, 99, 97]
            },
            models: {
                labels: ['GPT-4', 'Claude', 'Gemini', '本地模型'],
                data: [92, 88, 75, 82]
            }
        };

        const newData = dataMap[tabName] || dataMap.usage;
        this.charts.analysis.data.labels = newData.labels;
        this.charts.analysis.data.datasets[0].data = newData.data;
        this.charts.analysis.update();
    }

    generateCards() {
        const cardType = document.querySelector('.generation-form select').value;
        const quantity = parseInt(document.querySelector('.generation-form input[type="number"]').value);
        
        // 模拟卡密生成
        this.showNotification(`正在生成 ${quantity} 张${cardType}卡密...`, 'info');
        
        setTimeout(() => {
            this.showNotification(`成功生成 ${quantity} 张卡密！`, 'success');
            this.mockData.cardStats.generated += quantity;
            this.mockData.cardStats.available += quantity;
            this.updateCardStats();
            this.addNewCardsToTable(quantity, cardType);
        }, 2000);
    }

    addNewCardsToTable(quantity, cardType) {
        const tableBody = document.querySelector('.card-table .table-body');
        if (!tableBody) return;

        for (let i = 0; i < quantity; i++) {
            const cardCode = this.generateCardCode();
            const row = document.createElement('div');
            row.className = 'table-row';
            row.innerHTML = `
                <div class="col card-code">${cardCode}</div>
                <div class="col">${cardType}</div>
                <div class="col">
                    <span class="status-badge available">待使用</span>
                </div>
                <div class="col">${new Date().toLocaleDateString()}</div>
                <div class="col">
                    <button class="action-btn view">
                        <i class="fas fa-eye"></i>
                    </button>
                    <button class="action-btn copy">
                        <i class="fas fa-copy"></i>
                    </button>
                    <button class="action-btn delete">
                        <i class="fas fa-trash"></i>
                    </button>
                </div>
            `;
            tableBody.insertBefore(row, tableBody.firstChild);
        }
    }

    generateCardCode() {
        const chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
        const segments = [];
        
        for (let i = 0; i < 4; i++) {
            let segment = '';
            for (let j = 0; j < 4; j++) {
                segment += chars.charAt(Math.floor(Math.random() * chars.length));
            }
            segments.push(segment);
        }
        
        return 'NK-' + segments.join('-');
    }

    handleAction(btn) {
        const icon = btn.querySelector('i').classList[1];
        
        switch (icon) {
            case 'fa-edit':
                this.showNotification('打开编辑界面...', 'info');
                break;
            case 'fa-trash':
                if (confirm('确定要删除吗？')) {
                    btn.closest('.table-row, .permission-item').remove();
                    this.showNotification('删除成功', 'success');
                }
                break;
            case 'fa-eye':
                this.showNotification('查看详情...', 'info');
                break;
            case 'fa-copy':
                this.copyToClipboard(btn);
                break;
            case 'fa-key':
                this.showNotification('密码重置邮件已发送', 'success');
                break;
            case 'fa-ban':
                this.showNotification('用户已被封禁', 'warning');
                break;
            case 'fa-redo':
                this.showNotification('账户已续期', 'success');
                break;
        }
    }

    copyToClipboard(btn) {
        const cardCode = btn.closest('.table-row').querySelector('.card-code').textContent;
        navigator.clipboard.writeText(cardCode).then(() => {
            this.showNotification('卡密已复制到剪贴板', 'success');
        }).catch(() => {
            this.showNotification('复制失败', 'error');
        });
    }

    handleQuickOperation(btn) {
        const operation = btn.querySelector('.op-text').textContent;
        this.showNotification(`正在执行：${operation}`, 'info');
        
        // 模拟操作完成
        setTimeout(() => {
            this.showNotification(`${operation} 完成`, 'success');
        }, 2000);
    }

    updateChartsData() {
        // 重新加载图表数据
        setTimeout(() => {
            Object.values(this.charts).forEach(chart => {
                if (chart && chart.update) {
                    chart.update();
                }
            });
        }, 100);
    }

    startRealTimeUpdates() {
        // 每30秒更新一次实时数据
        setInterval(() => {
            if (this.currentLevel === 'level1') {
                this.updateSystemStats();
            }
        }, 30000);
    }

    loadDashboardData() {
        // 加载仪表盘数据
        this.updateMetricsOverview();
    }

    showNotification(message, type = 'info') {
        // 创建通知元素
        const notification = document.createElement('div');
        notification.className = `admin-notification ${type}`;
        notification.innerHTML = `
            <div class="notification-content">
                <i class="fas ${this.getNotificationIcon(type)}"></i>
                <span>${message}</span>
            </div>
        `;
        
        // 添加样式
        Object.assign(notification.style, {
            position: 'fixed',
            top: '2rem',
            right: '2rem',
            padding: '1rem 1.5rem',
            borderRadius: '8px',
            background: type === 'success' ? 'rgba(0, 255, 136, 0.2)' : 
                       type === 'error' ? 'rgba(255, 77, 77, 0.2)' : 
                       type === 'warning' ? 'rgba(255, 215, 0, 0.2)' :
                       'rgba(0, 191, 255, 0.2)',
            border: `1px solid ${type === 'success' ? '#00FF88' : 
                                type === 'error' ? '#FF4D4D' : 
                                type === 'warning' ? '#FFD700' :
                                '#00BFFF'}`,
            color: '#CCD6F6',
            zIndex: '9999',
            transform: 'translateX(100%)',
            transition: 'transform 0.3s ease',
            backdropFilter: 'blur(10px)',
            boxShadow: '0 4px 20px rgba(0, 0, 0, 0.3)'
        });
        
        document.body.appendChild(notification);
        
        // 动画显示
        requestAnimationFrame(() => {
            notification.style.transform = 'translateX(0)';
        });
        
        // 自动消失
        setTimeout(() => {
            notification.style.transform = 'translateX(100%)';
            setTimeout(() => {
                if (document.body.contains(notification)) {
                    document.body.removeChild(notification);
                }
            }, 300);
        }, 3000);
    }

    getNotificationIcon(type) {
        switch (type) {
            case 'success': return 'fa-check-circle';
            case 'error': return 'fa-exclamation-circle';
            case 'warning': return 'fa-exclamation-triangle';
            default: return 'fa-info-circle';
        }
    }
}

// 页面加载完成后初始化管理员控制台
document.addEventListener('DOMContentLoaded', () => {
    window.adminConsole = new AdminConsole();
    
    // 添加额外的管理员界面交互效果
    addAdminHoverEffects();
});

function addAdminHoverEffects() {
    // 为管理员面板添加悬停效果
    document.querySelectorAll('.admin-panel').forEach(panel => {
        panel.addEventListener('mouseenter', () => {
            panel.style.transform = 'translateY(-3px)';
        });
        
        panel.addEventListener('mouseleave', () => {
            panel.style.transform = 'translateY(0)';
        });
    });

    // 为指标卡片添加点击效果
    document.querySelectorAll('.metric-card').forEach(card => {
        card.addEventListener('click', () => {
            card.style.transform = 'scale(0.98)';
            setTimeout(() => {
                card.style.transform = 'scale(1)';
            }, 150);
        });
    });
}

// 全局管理员工具函数
window.AdminUtils = {
    formatNumber: (num) => {
        if (num >= 1000000) {
            return (num / 1000000).toFixed(1) + 'M';
        } else if (num >= 1000) {
            return (num / 1000).toFixed(1) + 'K';
        }
        return num.toString();
    },
    
    formatPercentage: (value, total) => {
        return ((value / total) * 100).toFixed(1) + '%';
    },
    
    generateReport: (data) => {
        // 生成报表的工具函数
        console.log('生成报表:', data);
    }
};