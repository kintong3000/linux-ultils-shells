#!/bin/bash

# 定义 Docker 容器名称和数据库认证信息
CONTAINER_NAME="mysql_container"
DB_USER="your_username"
DB_PASSWORD="your_password"

# 定义备份文件的存储位置
BACKUP_DIR="/backup/db"

# 创建存储备份的目录（如果它不存在的话）
mkdir -p "$BACKUP_DIR"

# 定义备份文件的名称格式
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/mydb_$DATE.sql"

# 使用 docker exec 执行 mysqldump
docker exec $CONTAINER_NAME mysqldump -u $DB_USER -p$DB_PASSWORD --all-databases > $BACKUP_FILE



echo "Database backup has been created successfully in the Docker container."


# 删除超过7天的备份
find $BACKUP_DIR -type f -name '*.sql' -mtime +7 -exec rm {} \;

echo "Old backups older than a week have been deleted."
