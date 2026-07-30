#!/usr/bin/env bash
# Frappe-Bench Cleanup Script - GitHub Ready
# Remove unnecessary files and directories

set -e  # Exit on any error

echo "Cleaning up Frappe Bench project for GitHub..."

# Remove unnecessary directories
rm -rf env/ logs/ tmp/ sites/assets sites/*/private sites/*/public/files sites/*/private/files sites/*/backups 2>/dev/null || true
rm -rf apps/frappe/node_modules apps/erpnext/node_modules apps/foundry_erp/node_modules 2>/dev/null || true
rm -rf env/lib/python3.12/site-packages 2>/dev/null || true
rm -rf __pycache__/ 2>/dev/null || true
rm -rf *.pyc *.log *.rdb dump.rdb 2>/dev/null || true
rm -rf OS-specific* tmp_* *_V* *_S* 2>/dev/null || true

# Remove specific unnecessary files
rm -f patches.txt 2>/dev/null || true
rm -f *.sql 2>/dev/null || true
rm -f check_mi_flow.py check_page.py 2>/dev/null || true
rm -f FIX_GUIDE.md 2>/dev/null || true
rm -f tmp_check.sql 2>/dev/null || true

# Remove log files
find . -name "*.log" -type f -delete 2>/dev/null || true

# Remove __pycache__ directories recursively
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true

# Remove .pyc files recursively
find . -type f -name "*.pyc" -delete 2>/dev/null || true

echo "Cleanup complete! Project is now GitHub-ready."
