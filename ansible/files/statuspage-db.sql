USE statuspage;

GRANT ALL ON statuspage.* TO statuspage@'%' IDENTIFIED BY 'statuspage';

CREATE TABLE IF NOT EXISTS statuspage.components (name VARCHAR(100), status TINYINT);
CREATE TABLE IF NOT EXISTS statuspage.incidents (datetime DATETIME, description TEXT);

INSERT INTO statuspage.components (name, status) VALUES("application", 0);
INSERT INTO statuspage.components (name, status) VALUES("database", 0);
INSERT INTO statuspage.components (name, status) VALUES("loadbalancer", 0);

INSERT INTO statuspage.incidents (datetime, description) VALUES("2018-03-16 06:39:13", "Increased database latency.");
INSERT INTO statuspage.incidents (datetime, description) VALUES("2018-03-19 18:43:54", "Partial loadbalancer outage.");
INSERT INTO statuspage.incidents (datetime, description) VALUES("2018-03-22 11:12:22", "Increased database latency.");
INSERT INTO statuspage.incidents (datetime, description) VALUES("2018-03-09 13:27:06", "Scheduled maintenance.");