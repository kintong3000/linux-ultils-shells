#!/bin/bash

source /root/restic_backup/backup_config.conf

# Check for required commands
for cmd in restic curl hostname; do
    if ! command -v $cmd &> /dev/null; then
        echo "Error: Required command '$cmd' not found. Exiting."
        exit 1
    fi
done

export RCLONE_TRANSFERS=$RCLONE_TRANSFERS
export RCLONE_CHECKERS=$RCLONE_CHECKERS

backup_success=true
backup_status="successful"  # Default status

send_email() {
    local subject_date=$(date +%Y-%m-%d)  # 当天日期
    local email_subject="Backup $backup_status on $subject_date"  # 邮件主题，包含当天日期和是否成功

    local message="$1"  # 邮件内容
    local recipient="cheungkintong3000@gmail.com"  # 收件人邮箱地址

    if [[ -z "$message" ]]; then
        echo "邮件内容未设置。跳过发送。"
        return 1
    fi
    local email_content="To: $recipient\nSubject: $email_subject\n\n$message"
    # 发送邮件
    if ! echo -e "$email_content" | msmtp "$recipient" > /dev/null; then
        echo "警告：发送邮件失败。"
    fi
}

backup_and_cleanup() {
    local retries=2
    local delay=10  # Initial retry delay in seconds
    local attempt=0
    local start_time=$(date +%s)
    local end_time
    local stats_output
    local cleanup_output=""
    
    # Start backup process
    echo "Starting backup at $(date), attempt $((attempt+1))" >> "$LOG_FILE"

    while [ $attempt -le $retries ]; do
        if restic -r "$RESTIC_REPOSITORY" --password-file "$PASSWORD_FILE" backup --files-from "$FILES_FROM" --exclude-file="$EXCLUDE_FILE" --tag "$BACKUP_TAG" >> "$LOG_FILE" 2>&1; then
            end_time=$(date +%s)
            echo "Backup completed successfully at $(date). Duration: $((end_time - start_time)) seconds." >> "$LOG_FILE"
            stats_output=$(restic -r "$RESTIC_REPOSITORY" --password-file "$PASSWORD_FILE" stats | awk '/Stats in restore-size mode:/,0')
            break
        else
            attempt=$((attempt + 1))
            echo "Backup failed, attempt $((attempt+1)) at $(date). Check log $LOG_FILE for details." >> "$LOG_FILE"
            sleep $delay
            delay=$((delay * 2))  # Exponential backoff
            if [ $attempt -gt $retries ]; then
                backup_success=false
                backup_status="failed"
                echo "Backup failed after $retries retries at $(date +%Y-%m-%d\ %H:%M:%S)." >> "$LOG_FILE"
                break
            fi
        fi
    done
    
    # Start cleanup process
    if $backup_success; then
        echo "Starting cleanup process at $(date)" >> "$LOG_FILE"
        if restic -r "$RESTIC_REPOSITORY" --password-file "$PASSWORD_FILE" forget --keep-last "$KEEP_SNAPSHOTS" --prune >>"$LOG_FILE" 2>&1; then
            cleanup_output="Cleanup completed successfully at $(date). Kept the last $KEEP_SNAPSHOTS snapshots."
        else
            cleanup_output="Cleanup failed at $(date), see log for details."
            backup_status="failed"
        fi
    else
        cleanup_output="Cleanup skipped due to backup failure."
    fi
    
    # Send email summary
    send_email "🗓️ Date: $(date +%Y-%m-%d)
🖥️ Hostname: $HOSTNAME
🌐 IP Address: $(curl -s ip.sb)
💾 Repository: $RESTIC_REPOSITORY

📋 Backup Summary:
$stats_output

🧹 Cleanup Summary:
$cleanup_output

Check log $LOG_FILE for more details."
}

# Start the backup and cleanup process, then send a summary email
backup_and_cleanup
