// ===== NovelForge Sentinel Pro 主界面脚本 =====

class NovelForgeApp {
    constructor() {
        this.init();
        this.bindEvents();
        this.startAnimations();
    }

    init() {
        // 初始化应用状态
        this.currentSection = 'creation';
        this.workflowStatus = {
            worldview: 'waiting',
            outline: 'waiting',
            characters: 'waiting',
            style: 'waiting',
            conflict: 'waiting'
        };
        
        // 模拟数据
        this.mockData = {
            cpuUsage: 45,
            memoryUsage: 35,
            projects: [],
            modelStatus: {
                gpt: 'connected',
                claude: 'connected',
                gemini: 'disconnected'
            }
        };
    }

    bindEvents() {
        // 导航切换
        document.querySelectorAll('.nav-item').forEach(item => {
            item.addEventListener('click', (e) => {
                this.switchSection(item.dataset.section);
            });
        });

        // 创作表单提交
        const creationForm = document.querySelector('.creation-form');
        if (creationForm) {
            creationForm.addEventListener('submit', (e) => {
                e.preventDefault();
                this.startCreationWorkflow();
            });
        }

        // 风格选择按钮
        document.querySelectorAll('.style-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                document.querySelectorAll('.style-btn').forEach(b => b.classList.remove('active'));
                btn.classList.add('active');
            });
        });

        // 滑块值更新
        const slider = document.querySelector('.cyber-slider');
        if (slider) {
            slider.addEventListener('input', (e) => {
                const value = parseInt(e.target.value);
                const valueDisplay = document.querySelector('.slider-value');
                if (valueDisplay) {
                    valueDisplay.textContent = `${value.toLocaleString()} 字`;
                }
            });
        }

        // 切换开关
        document.querySelectorAll('.toggle-switch').forEach(toggle => {
            toggle.addEventListener('click', () => {
                toggle.classList.toggle('active');
            });
        });

        // API管理按钮
        const manageApiBtn = document.querySelector('.manage-api-btn');
        if (manageApiBtn) {
            manageApiBtn.addEventListener('click', () => {
                this.showApiManagement();
            });
        }

        // 项目操作按钮
        document.querySelectorAll('.action-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                e.stopPropagation();
                this.handleProjectAction(btn);
            });
        });
    }

    switchSection(sectionName) {
        // 更新导航状态
        document.querySelectorAll('.nav-item').forEach(item => {
            item.classList.remove('active');
        });
        document.querySelector(`[data-section="${sectionName}"]`).classList.add('active');

        // 切换内容区域
        document.querySelectorAll('.content-section').forEach(section => {
            section.classList.remove('active');
        });
        document.getElementById(`${sectionName}-section`).classList.add('active');

        this.currentSection = sectionName;

        // 触发特定区域的初始化
        this.initializeSection(sectionName);
    }

    initializeSection(sectionName) {
        switch (sectionName) {
            case 'creation':
                this.updateResourceStats();
                break;
            case 'projects':
                this.loadProjects();
                break;
            case 'ai-models':
                this.updateModelStatus();
                break;
            case 'settings':
                this.loadSettings();
                break;
        }
    }

    startCreationWorkflow() {
        const workflows = ['worldview', 'outline', 'characters', 'style', 'conflict'];
        const workflowItems = document.querySelectorAll('.workflow-item');
        
        // 更新工作流程状态指示器
        const statusIndicator = document.querySelector('.workflow-status .status-indicator');
        const statusText = document.querySelector('.workflow-status span');
        
        statusIndicator.className = 'status-indicator processing';
        statusText.textContent = '生成中';

        // 模拟并行处理
        workflows.forEach((workflow, index) => {
            setTimeout(() => {
                this.updateWorkflowItem(workflow, 'processing');
                
                // 模拟进度更新
                let progress = 0;
                const progressInterval = setInterval(() => {
                    progress += Math.random() * 20;
                    if (progress >= 100) {
                        progress = 100;
                        clearInterval(progressInterval);
                        setTimeout(() => {
                            this.updateWorkflowItem(workflow, 'completed');
                            
                            // 检查是否全部完成
                            if (this.checkAllWorkflowsCompleted()) {
                                statusIndicator.className = 'status-indicator completed';
                                statusText.textContent = '已完成';
                                this.showNotification('专业创作流程已完成！', 'success');
                            }
                        }, 500);
                    }
                    this.updateWorkflowProgress(workflow, progress);
                }, 100 + Math.random() * 200);
                
            }, index * 500 + Math.random() * 1000);
        });
    }

    updateWorkflowItem(workflow, status) {
        const workflowItems = document.querySelectorAll('.workflow-item');
        const workflowMap = {
            worldview: 0,
            outline: 1,
            characters: 2,
            style: 3,
            conflict: 4
        };
        
        const item = workflowItems[workflowMap[workflow]];
        if (item) {
            item.setAttribute('data-status', status);
            const statusText = item.querySelector('.workflow-status');
            
            const statusMap = {
                waiting: '等待中',
                processing: '生成中',
                completed: '已完成',
                error: '出错'
            };
            
            statusText.textContent = statusMap[status] || '未知';
        }
    }

    updateWorkflowProgress(workflow, progress) {
        const workflowItems = document.querySelectorAll('.workflow-item');
        const workflowMap = {
            worldview: 0,
            outline: 1,
            characters: 2,
            style: 3,
            conflict: 4
        };
        
        const item = workflowItems[workflowMap[workflow]];
        if (item) {
            const progressFill = item.querySelector('.progress-fill');
            if (progressFill) {
                progressFill.style.width = `${progress}%`;
            }
        }
    }

    checkAllWorkflowsCompleted() {
        const workflowItems = document.querySelectorAll('.workflow-item');
        return Array.from(workflowItems).every(item => 
            item.getAttribute('data-status') === 'completed'
        );
    }

    updateResourceStats() {
        // 模拟资源使用情况更新
        setInterval(() => {
            const cpuStat = document.querySelector('.stat-item .stat-value');
            const memoryInfo = document.querySelectorAll('.stat-item .stat-value')[1];
            
            // 随机更新CPU使用率
            const newCpuUsage = Math.max(20, Math.min(80, this.mockData.cpuUsage + (Math.random() - 0.5) * 10));
            this.mockData.cpuUsage = newCpuUsage;
            
            if (cpuStat) {
                cpuStat.textContent = `${Math.round(newCpuUsage)}%`;
                const cpuFill = cpuStat.closest('.stat-item').querySelector('.stat-fill');
                if (cpuFill) {
                    cpuFill.style.width = `${newCpuUsage}%`;
                }
            }
            
        }, 3000);
    }

    loadProjects() {
        // 项目数据已在HTML中静态定义，这里可以添加动态加载逻辑
        console.log('加载项目列表...');
    }

    updateModelStatus() {
        // 更新AI模型连接状态
        const models = document.querySelectorAll('.ai-model');
        models.forEach(model => {
            const indicator = model.querySelector('.model-indicator');
            const status = model.querySelector('.model-status');
            
            // 模拟连接状态检查
            setTimeout(() => {
                if (Math.random() > 0.1) { // 90%的概率保持连接
                    indicator.className = 'model-indicator connected';
                    status.textContent = '已连接';
                } else {
                    indicator.className = 'model-indicator disconnected';
                    status.textContent = '连接超时';
                }
            }, Math.random() * 2000);
        });
    }

    loadSettings() {
        console.log('加载设置...');
    }

    showApiManagement() {
        // 这里可以打开API管理模态框
        this.switchSection('ai-models');
        this.showNotification('已切换到AI模型管理', 'info');
    }

    handleProjectAction(btn) {
        const action = btn.querySelector('i').classList[1]; // 获取图标类名来确定操作类型
        
        switch (action) {
            case 'fa-edit':
                this.showNotification('打开编辑器...', 'info');
                break;
            case 'fa-download':
                this.showNotification('开始下载...', 'success');
                break;
            case 'fa-trash':
                if (confirm('确定要删除这个项目吗？')) {
                    this.showNotification('项目已删除', 'success');
                }
                break;
            case 'fa-eye':
                this.showNotification('查看项目详情...', 'info');
                break;
            case 'fa-share':
                this.showNotification('准备分享...', 'info');
                break;
        }
    }

    showNotification(message, type = 'info') {
        // 创建通知元素
        const notification = document.createElement('div');
        notification.className = `notification ${type}`;
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
                       'rgba(0, 191, 255, 0.2)',
            border: `1px solid ${type === 'success' ? 'var(--success-green)' : 
                                type === 'error' ? 'var(--danger-red)' : 
                                'var(--accent-blue)'}`,
            color: 'var(--text-primary)',
            zIndex: '9999',
            transform: 'translateX(100%)',
            transition: 'transform 0.3s ease',
            backdropFilter: 'blur(10px)'
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
                document.body.removeChild(notification);
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

    startAnimations() {
        // 启动背景动画和其他动态效果
        this.animateParticles();
        this.animateSecurityIndicator();
    }

    animateParticles() {
        // 粒子动画已通过CSS实现
        console.log('粒子动画已启动');
    }

    animateSecurityIndicator() {
        // 安全指示器脉冲动画
        const indicators = document.querySelectorAll('.security-indicator, .model-indicator');
        indicators.forEach(indicator => {
            if (indicator.classList.contains('active') || indicator.classList.contains('connected')) {
                // CSS动画已处理
            }
        });
    }
}

// 页面加载完成后初始化应用
document.addEventListener('DOMContentLoaded', () => {
    window.novelForgeApp = new NovelForgeApp();
    
    // 添加一些额外的交互效果
    addHoverEffects();
    addScrollEffects();
});

function addHoverEffects() {
    // 为面板添加悬停效果
    document.querySelectorAll('.glass-panel').forEach(panel => {
        panel.addEventListener('mouseenter', () => {
            panel.style.transform = 'translateY(-3px)';
        });
        
        panel.addEventListener('mouseleave', () => {
            panel.style.transform = 'translateY(0)';
        });
    });
}

function addScrollEffects() {
    // 滚动时的视差效果
    window.addEventListener('scroll', () => {
        const scrolled = window.pageYOffset;
        const bg = document.querySelector('.bg-animation');
        if (bg) {
            bg.style.transform = `translateY(${scrolled * 0.1}px)`;
        }
    });
}

// 全局工具函数
window.NovelForgeUtils = {
    formatFileSize: (bytes) => {
        const sizes = ['B', 'KB', 'MB', 'GB'];
        if (bytes === 0) return '0 B';
        const i = Math.floor(Math.log(bytes) / Math.log(1024));
        return Math.round(bytes / Math.pow(1024, i) * 100) / 100 + ' ' + sizes[i];
    },
    
    formatDate: (date) => {
        return new Date(date).toLocaleDateString('zh-CN', {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit'
        });
    },
    
    generateRandomId: () => {
        return 'NF' + Math.random().toString(36).substr(2, 9).toUpperCase();
    }
};