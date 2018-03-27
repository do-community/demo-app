# App

Sample status page application intended to be deployed on Digital Ocean for demonstrative purposes.

### Local Environment Setup

If you would like to run this application independently such as in a local environment, you must first create a MySQL database. The following instructions show how you can do this with docker-compose.

First, create a `docker-compose.yml`:

```
version: '2'

services:
  db:
    image: mysql:5.7
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: <some-password>
      MYSQL_DATABASE: statuspage
      MYSQL_USER: digitalocean
      MYSQL_PASSWORD: <another-password>
    ports:
      - "3306:3306"
```

Run the database container with:

```
docker-compose up -d
```

Next create the necessary tables and some seed data:

```
docker-compose exec db \
  sh -c 'exec mysql -uroot -p<root-pw> -e "

CREATE TABLE IF NOT EXISTS statuspage.components (name VARCHAR(100), status TINYINT);
CREATE TABLE IF NOT EXISTS statuspage.incidents (datetime DATETIME, description TEXT);

INSERT INTO statuspage.components (name, status) VALUES(\"application\", 0);
INSERT INTO statuspage.components (name, status) VALUES(\"database\", 0);
INSERT INTO statuspage.components (name, status) VALUES(\"loadbalancer\", 0);

INSERT INTO statuspage.incidents (datetime, description) VALUES(\"2018-03-16 06:39:13\", \"Increased database latency.\");
INSERT INTO statuspage.incidents (datetime, description) VALUES(\"2018-03-19 18:43:54\", \"Partial loadbalancer outage.\");
INSERT INTO statuspage.incidents (datetime, description) VALUES(\"2018-03-22 11:12:22\", \"Increased database latency.\");
INSERT INTO statuspage.incidents (datetime, description) VALUES(\"2018-03-09 13:27:06\", \"Scheduled maintenance.\");
"'
```

Once this is done and assuming you have a Go environment set up, run the application with:

```
MYSQL_DATABASE=statuspage \
MYSQL_HOST=localhost \
MYSQL_PORT=3306 \
MYSQL_PASSWORD=<another-password> \
MYSQL_USER=digitalocean \
go run main.go
```

You should then be able to browse to http://localhost:8080/.
