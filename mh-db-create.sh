#!/bin/sh

if [ $# -eq 0 ]; then
	echo "please provide the database name to recreate"
	exit 1
fi

db=$1

mysql -u root << EOF 2>/dev/null
use $db;
EOF

if [ $? -eq 0 ]; then
	echo "Database $db already exists. Dropping..."
	mysql -u root << EOF 2>/dev/null
drop database $1;
EOF
fi

echo "Creating $db"	
mysql -u root << EOF 2>/dev/null
create database $1;
grant all on $1.* to 'matterhorn'@'localhost';
EOF

if [ $? -ne 0 ]; then
	echo "Error creating $db"
	exit 1
fi
 
