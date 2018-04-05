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
CREATE TABLE IF NOT EXISTS statuspage.incidents (datetime DATETIME, title VARCHAR(100), description TEXT);

INSERT INTO statuspage.components (name, status) VALUES(\\\"application\\\", 0);
INSERT INTO statuspage.components (name, status) VALUES(\\\"database\\\", 0);
INSERT INTO statuspage.components (name, status) VALUES(\\\"loadbalancer\\\", 0);

INSERT INTO statuspage.incidents (datetime, title, description) VALUES(DATE_SUB(NOW(), INTERVAL \\\"1 1:1:1\\\" DAY_SECOND), \\\"Increased Database Latency\\\", \\\"Requests to the bathtub API function are currently overflowing and we are experiencing delays in processing the events. We are actively working on remediation to keep our ducks in a row.\\\");
INSERT INTO statuspage.incidents (datetime, title, description) VALUES(DATE_SUB(NOW(), INTERVAL \\\"5 6:0:30\\\" DAY_SECOND), \\\"Packet Loss\\\", \\\"Some packets seem to have slipped down the drain. We're working to increase our bandwidth and hopefully nothing else will run afowl.\\\");
INSERT INTO statuspage.incidents (datetime, title, description) VALUES(DATE_SUB(NOW(), INTERVAL \\\"8 11:12:23\\\" DAY_SECOND), \\\"Event Processing Delays\\\", \\\"Our team has resolved the issue with bath time processing delays. If you continue to experience problems, please quack at us and we will put a solution in flight.\\\");
INSERT INTO statuspage.incidents (datetime, title, description) VALUES(DATE_SUB(NOW(), INTERVAL \\\"10 18:43:58\\\" DAY_SECOND), \\\"Service Issues\\\", \\\"The developers are speaking nonsense at me while investigating what\'s wrong with the bubble service.\\\");
INSERT INTO statuspage.incidents (datetime, title, description) VALUES(DATE_SUB(NOW(), INTERVAL \\\"10 18:43:58\\\" DAY_SECOND), \\\"Network Issues\\\", \\\"Despite not having legs I tripped over the cord for the router. We should be swimming again momentarily.\\\");
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
