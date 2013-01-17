#!/bin/sh

mysql -u root << EOF 2>/dev/null
show databases;
EOF
 
