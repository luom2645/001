#!/usr/bin/env python3
"""
NovelForge Sentinel Pro 项目验证脚本
验证项目结构、文件完整性和配置正确性
"""

import os
import json
import re
import hashlib
from pathlib import Path
from typing import Dict, List, Tuple
import logging

# 设置日志
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class ProjectValidator:
    def __init__(self, project_root: str):
        self.project_root = Path(project_root)
        self.errors = []
        self.warnings = []
        self.success_count = 0
        self.total_checks = 0
        
    def log_result(self, test_name: str, success: bool, message: str = ""):
        """记录测试结果"""
        self.total_checks += 1
        if success:
            self.success_count += 1
            logger.info(f"✅ {test_name}: {message}")
            return True
        else:
            self.errors.append(f"{test_name}: {message}")
            logger.error(f"❌ {test_name}: {message}")
            return False
    
    def log_warning(self, test_name: str, message: str):
        """记录警告"""
        self.warnings.append(f"{test_name}: {message}")
        logger.warning(f"⚠️  {test_name}: {message}")
    
    def validate_project_structure(self) -> bool:
        """验证项目目录结构"""
        logger.info("🔍 验证项目结构...")
        
        required_dirs = [
            "docs",
            "novelforge-sentinel-pro",
            "novelforge-sentinel-pro/css",
            "novelforge-sentinel-pro/js", 
            "novelforge-sentinel-pro/images",
            "novelforge-sentinel-pro/data",
            "supabase",
            "supabase/functions",
            "supabase/tables",
            "supabase/migrations",
            "supabase/cron_jobs",
            "tests"
        ]
        
        required_files = [
            "todo.md",
            "deploy_url.txt",
            "novelforge-sentinel-pro/index.html",
            "novelforge-sentinel-pro/admin.html",
            "supabase/config.json"
        ]
        
        # 检查目录
        all_dirs_exist = True
        for dir_path in required_dirs:
            full_path = self.project_root / dir_path
            if full_path.exists() and full_path.is_dir():
                self.log_result(f"目录检查", True, f"{dir_path} 存在")
            else:
                self.log_result(f"目录检查", False, f"{dir_path} 不存在")
                all_dirs_exist = False
        
        # 检查文件
        all_files_exist = True  
        for file_path in required_files:
            full_path = self.project_root / file_path
            if full_path.exists() and full_path.is_file():
                self.log_result(f"文件检查", True, f"{file_path} 存在")
            else:
                self.log_result(f"文件检查", False, f"{file_path} 不存在")
                all_files_exist = False
        
        return all_dirs_exist and all_files_exist
    
    def validate_edge_functions(self) -> bool:
        """验证Edge Functions完整性"""
        logger.info("🔍 验证Edge Functions...")
        
        expected_functions = [
            "admin-setup",
            "ai-proxy", 
            "device-verification",
            "file-upload",
            "license-management",
            "security-monitoring",
            "security-scan-cron",
            "create-bucket-novel-documents-temp",
            "create-bucket-user-avatars-temp"
        ]
        
        functions_dir = self.project_root / "supabase" / "functions"
        all_functions_exist = True
        
        for func_name in expected_functions:
            func_dir = functions_dir / func_name
            index_file = func_dir / "index.ts"
            
            if func_dir.exists() and index_file.exists():
                # 检查文件大小（确保不是空文件）
                file_size = index_file.stat().st_size
                if file_size > 100:  # 至少100字节
                    self.log_result(f"Edge Function", True, f"{func_name} 完整")
                else:
                    self.log_result(f"Edge Function", False, f"{func_name} 文件过小 ({file_size} bytes)")
                    all_functions_exist = False
            else:
                self.log_result(f"Edge Function", False, f"{func_name} 不存在")
                all_functions_exist = False
        
        return all_functions_exist
    
    def validate_database_files(self) -> bool:
        """验证数据库相关文件"""
        logger.info("🔍 验证数据库文件...")
        
        expected_tables = [
            "ai_usage_logs.sql",
            "audit_logs.sql", 
            "device_bindings.sql",
            "licenses.sql",
            "novels.sql",
            "profiles.sql",
            "security_events.sql",
            "system_notifications.sql"
        ]
        
        expected_migrations = [
            "1754354212_setup_indexes_and_rls.sql",
            "1754354231_create_rls_policies.sql",
            "1754354248_create_audit_triggers.sql"
        ]
        
        tables_dir = self.project_root / "supabase" / "tables"
        migrations_dir = self.project_root / "supabase" / "migrations"
        
        all_db_files_exist = True
        
        # 检查表文件
        for table_file in expected_tables:
            file_path = tables_dir / table_file
            if file_path.exists() and file_path.stat().st_size > 0:
                self.log_result(f"数据库表", True, f"{table_file} 存在")
            else:
                self.log_result(f"数据库表", False, f"{table_file} 不存在或为空")
                all_db_files_exist = False
        
        # 检查迁移文件
        for migration_file in expected_migrations:
            file_path = migrations_dir / migration_file
            if file_path.exists() and file_path.stat().st_size > 0:
                self.log_result(f"数据库迁移", True, f"{migration_file} 存在")
            else:
                self.log_result(f"数据库迁移", False, f"{migration_file} 不存在或为空")
                all_db_files_exist = False
        
        return all_db_files_exist
    
    def validate_security_fixes(self) -> bool:
        """验证安全修复是否已应用"""
        logger.info("🔍 验证安全修复...")
        
        # 检查是否存在修复版本的存储桶脚本
        security_fixes_applied = True
        
        bucket_functions = [
            "create-bucket-novel-documents-temp",
            "create-bucket-user-avatars-temp"
        ]
        
        for func_name in bucket_functions:
            original_file = self.project_root / "supabase" / "functions" / func_name / "index.ts"
            fixed_file = self.project_root / "supabase" / "functions" / func_name / "index.ts.fixed"
            
            # 检查是否存在修复版本
            if fixed_file.exists():
                self.log_result(f"安全修复", True, f"{func_name} 修复版本存在")
                
                # 检查原始文件是否包含不安全的 public: true
                if original_file.exists():
                    content = original_file.read_text()
                    if 'public: true' in content and 'Public Access' in content:
                        self.log_warning(f"安全风险", f"{func_name} 原始文件仍包含不安全配置")
                        
            else:
                self.log_result(f"安全修复", False, f"{func_name} 修复版本不存在")
                security_fixes_applied = False
        
        # 检查是否存在安全修复文档
        security_doc = self.project_root / "docs" / "security_fixes_and_improvements.md"
        if security_doc.exists():
            self.log_result(f"安全文档", True, "安全修复文档存在")
        else:
            self.log_result(f"安全文档", False, "安全修复文档不存在")
            security_fixes_applied = False
        
        return security_fixes_applied
    
    def validate_documentation(self) -> bool:
        """验证文档完整性"""
        logger.info("🔍 验证文档完整性...")
        
        required_docs = [
            "technical_research_report.md",
            "system_architecture_design.md", 
            "technology_stack_recommendation.md",
            "security_analysis_report.md",
            "implementation_suggestion.md",
            "novelforge_sentinel_pro_api_documentation.md",
            "novelforge_sentinel_pro_completion_report.md",
            "novelforge_sentinel_pro_deployment_guide.md",
            "research_plan_NovelForge_Sentinel_Pro.md",
            "security_fixes_and_improvements.md",
            "updated_deployment_guide.md"
        ]
        
        docs_dir = self.project_root / "docs"
        all_docs_exist = True
        
        for doc_file in required_docs:
            file_path = docs_dir / doc_file
            if file_path.exists() and file_path.stat().st_size > 500:  # 至少500字节
                self.log_result(f"文档检查", True, f"{doc_file} 存在且有内容")
            else:
                if file_path.exists():
                    self.log_result(f"文档检查", False, f"{doc_file} 内容过少")
                else:
                    self.log_result(f"文档检查", False, f"{doc_file} 不存在")
                all_docs_exist = False
        
        return all_docs_exist
    
    def validate_frontend_assets(self) -> bool:
        """验证前端资源完整性"""
        logger.info("🔍 验证前端资源...")
        
        # 检查CSS文件
        css_files = ["styles.css", "admin.css"]
        js_files = ["main.js", "admin.js"]
        image_files = ["ai-neural.jpg", "bg-main.jpg", "data-flow.jpg", "panel-bg.jpg", "writing-space.jpg"]
        
        all_assets_exist = True
        
        # 检查CSS
        css_dir = self.project_root / "novelforge-sentinel-pro" / "css"
        for css_file in css_files:
            file_path = css_dir / css_file
            if file_path.exists() and file_path.stat().st_size > 1000:
                self.log_result(f"CSS文件", True, f"{css_file} 存在")
            else:
                self.log_result(f"CSS文件", False, f"{css_file} 不存在或过小")
                all_assets_exist = False
        
        # 检查JS
        js_dir = self.project_root / "novelforge-sentinel-pro" / "js"
        for js_file in js_files:
            file_path = js_dir / js_file
            if file_path.exists() and file_path.stat().st_size > 1000:
                self.log_result(f"JS文件", True, f"{js_file} 存在")
            else:
                self.log_result(f"JS文件", False, f"{js_file} 不存在或过小")
                all_assets_exist = False
        
        # 检查图片
        images_dir = self.project_root / "novelforge-sentinel-pro" / "images"
        for image_file in image_files:
            file_path = images_dir / image_file
            if file_path.exists() and file_path.stat().st_size > 5000:  # 图片至少5KB
                self.log_result(f"图片文件", True, f"{image_file} 存在")
            else:
                self.log_result(f"图片文件", False, f"{image_file} 不存在或过小")
                all_assets_exist = False
        
        return all_assets_exist
    
    def validate_configuration(self) -> bool:
        """验证配置文件"""
        logger.info("🔍 验证配置文件...")
        
        config_file = self.project_root / "supabase" / "config.json"
        
        if not config_file.exists():
            self.log_result(f"配置文件", False, "config.json 不存在")
            return False
            
        try:
            with open(config_file, 'r', encoding='utf-8') as f:
                config = json.load(f)
            
            # 检查必要的配置部分
            required_sections = ['project', 'supabase', 'security', 'ai_models', 'client']
            
            config_valid = True
            for section in required_sections:
                if section in config:
                    self.log_result(f"配置验证", True, f"{section} 部分存在")
                else:
                    self.log_result(f"配置验证", False, f"{section} 部分缺失")
                    config_valid = False
            
            return config_valid
            
        except json.JSONDecodeError:
            self.log_result(f"配置文件", False, "config.json 格式无效")
            return False
    
    def generate_report(self) -> Dict:
        """生成测试报告"""
        success_rate = (self.success_count / self.total_checks * 100) if self.total_checks > 0 else 0
        
        report = {
            "timestamp": "2025-08-06",
            "project_name": "NovelForge Sentinel Pro",
            "total_checks": self.total_checks,
            "successful_checks": self.success_count,
            "success_rate": f"{success_rate:.1f}%",
            "errors": self.errors,
            "warnings": self.warnings,
            "status": "PASS" if len(self.errors) == 0 else "FAIL"
        }
        
        return report
    
    def run_all_validations(self) -> bool:
        """运行所有验证检查"""
        logger.info("🚀 开始 NovelForge Sentinel Pro 项目验证")
        logger.info("=" * 50)
        
        results = []
        
        # 运行所有验证
        results.append(self.validate_project_structure())
        results.append(self.validate_edge_functions())
        results.append(self.validate_database_files())
        results.append(self.validate_security_fixes())
        results.append(self.validate_documentation())
        results.append(self.validate_frontend_assets())
        results.append(self.validate_configuration())
        
        # 生成报告
        report = self.generate_report()
        
        logger.info("=" * 50)
        logger.info("📊 验证结果汇总:")
        logger.info(f"总检查项: {report['total_checks']}")
        logger.info(f"成功项: {report['successful_checks']}")
        logger.info(f"成功率: {report['success_rate']}")
        logger.info(f"状态: {report['status']}")
        
        if report['errors']:
            logger.error("❌ 发现错误:")
            for error in report['errors']:
                logger.error(f"  - {error}")
        
        if report['warnings']:
            logger.warning("⚠️  警告信息:")
            for warning in report['warnings']:
                logger.warning(f"  - {warning}")
        
        # 保存报告
        report_file = self.project_root / "tests" / "validation_report.json"
        with open(report_file, 'w', encoding='utf-8') as f:
            json.dump(report, f, ensure_ascii=False, indent=2)
        
        logger.info(f"📄 详细报告已保存到: {report_file}")
        
        return report['status'] == 'PASS'

def main():
    """主函数"""
    # 项目根目录
    project_root = "/workspace/agent_workspace"
    
    # 创建验证器实例
    validator = ProjectValidator(project_root)
    
    # 运行验证
    success = validator.run_all_validations()
    
    # 退出状态
    exit(0 if success else 1)

if __name__ == "__main__":
    main()
