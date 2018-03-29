[Unit]
Description=Statuspage-Demo app
ConditionPathExists=/var/www/app/
After=network.target

[Service]
Type=simple
User=root
Group=root
LimitNOFILE=1024

Restart=on-failure
RestartSec=10

WorkingDirectory=/var/www/app/
ExecStart=/var/www/app/app

Environment=MYSQL_DATABASE=statuspage
Environment=MYSQL_HOST=${db_ip}
Environment=MYSQL_PORT=3306
Environment=MYSQL_PASSWORD=statuspage
Environment=MYSQL_USER=statuspage

[Install]
WantedBy=multi-user.target