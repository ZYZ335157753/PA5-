#!/bin/bash

# ==============================================================================
# Script Name: ops_manage.sh
# Description: Automated build, backup, and monitoring script for PA5 environment.
#              Demonstrates Linux system management and shell scripting skills.
# Author: Student
# Date: 2026-01-01
# ==============================================================================

# --- Configuration Variables ---
PROJECT_DIR=$(pwd)
BACKUP_DIR="${PROJECT_DIR}/backups"
LOG_FILE="${PROJECT_DIR}/ops_build.log"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
MAX_BACKUPS=5

# --- Color Codes for Output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# --- Helper Functions ---

log_message() {
    local level=$1
    local message=$2
    local log_entry="[$(date +'%Y-%m-%d %H:%M:%S')] [${level}] ${message}"
    echo -e "${log_entry}" >> "${LOG_FILE}"
    
    # Also print to stdout with color
    case $level in
        INFO) echo -e "${GREEN}${log_entry}${NC}" ;;
        WARN) echo -e "${YELLOW}${log_entry}${NC}" ;;
        ERROR) echo -e "${RED}${log_entry}${NC}" ;;
        *) echo "${log_entry}" ;;
    esac
}

check_dependency() {
    if ! command -v $1 &> /dev/null; then
        log_message "ERROR" "$1 could not be found. Please install it."
        exit 1
    else
        log_message "INFO" "Dependency check passed: $1"
    fi
}

# --- Main Execution ---

log_message "INFO" "Starting Automated Operations Script..."

# 1. Environment Check
log_message "INFO" "Checking system environment..."
check_dependency "g++"
check_dependency "make"
check_dependency "tar"

# Check Disk Space (Alert if less than 1GB free)
FREE_SPACE=$(df -k . | awk 'NR==2 {print $4}')
if [ "$FREE_SPACE" -lt 1048576 ]; then
    log_message "WARN" "Low disk space! Less than 1GB available."
else
    log_message "INFO" "Disk space check passed."
fi

# 2. Backup Source Code
log_message "INFO" "Starting source code backup..."
mkdir -p "${BACKUP_DIR}"

BACKUP_NAME="pa5_backup_${TIMESTAMP}.tar.gz"
tar -czf "${BACKUP_DIR}/${BACKUP_NAME}" --exclude="backups" --exclude="*.o" --exclude="cgen" . 2>/dev/null

if [ $? -eq 0 ]; then
    log_message "INFO" "Backup created successfully: ${BACKUP_DIR}/${BACKUP_NAME}"
else
    log_message "ERROR" "Backup failed!"
    exit 1
fi

# Rotate backups (Keep only last $MAX_BACKUPS)
BACKUP_COUNT=$(ls -1 "${BACKUP_DIR}"/*.tar.gz | wc -l)
if [ "$BACKUP_COUNT" -gt "$MAX_BACKUPS" ]; then
    log_message "INFO" "Cleaning up old backups..."
    ls -1t "${BACKUP_DIR}"/*.tar.gz | tail -n +$(($MAX_BACKUPS + 1)) | xargs rm -f
fi

# 3. Build Process
log_message "INFO" "Cleaning previous build..."
make clean >> "${LOG_FILE}" 2>&1

log_message "INFO" "Compiling project..."
make >> "${LOG_FILE}" 2>&1

if [ $? -eq 0 ]; then
    log_message "INFO" "Build successful."
else
    log_message "ERROR" "Build failed! Check ${LOG_FILE} for details."
    exit 1
fi

# 4. Automated Testing
log_message "INFO" "Running automated tests..."
make dotest >> "${LOG_FILE}" 2>&1

if [ $? -eq 0 ]; then
    log_message "INFO" "Tests completed successfully."
else
    log_message "ERROR" "Tests failed!"
    exit 1
fi

log_message "INFO" "Operations script finished successfully."
exit 0
