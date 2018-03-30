USE statuspage;

GRANT ALL ON statuspage.* TO statuspage@'%' IDENTIFIED BY 'statuspage';

CREATE TABLE IF NOT EXISTS statuspage.components (name VARCHAR(100), status TINYINT);
CREATE TABLE IF NOT EXISTS statuspage.incidents (datetime DATETIME, title VARCHAR(100), description TEXT);

INSERT INTO statuspage.components (name, status) VALUES("application", 0);
INSERT INTO statuspage.components (name, status) VALUES("database", 0);
INSERT INTO statuspage.components (name, status) VALUES("loadbalancer", 0);

INSERT INTO statuspage.incidents (datetime, title, description) VALUES(DATE_SUB(NOW(), INTERVAL "0 01:01:01" DAY_SECOND), "Increased Database Latency", "Requests to the bathtub API function are currently overflowing and we are experiencing delays in processing the events. We are actively working on remediation to keep our ducks in a row.");
INSERT INTO statuspage.incidents (datetime, title, description) VALUES(DATE_SUB(NOW(), INTERVAL "2 06:00:30" DAY_SECOND), "Packet Loss", "Some packets seem to have slipped down the drain. We're working to increase our bandwidth and hopefully nothing else will run afowl.");
INSERT INTO statuspage.incidents (datetime, title, description) VALUES(DATE_SUB(NOW(), INTERVAL "5 11:12:23" DAY_SECOND), "Event Processing Delays", "Our team has resolved the issue with bath time processing delays. If you continue to experience problems, please quack at us and we will put a solution in flight.");
INSERT INTO statuspage.incidents (datetime, title, description) VALUES(DATE_SUB(NOW(), INTERVAL "8 13:22:03" DAY_SECOND), "Service Issues", "The developers are speaking nonsense at me while investigating what's wrong with the bubble service.");
INSERT INTO statuspage.incidents (datetime, title, description) VALUES(DATE_SUB(NOW(), INTERVAL "9 17:43:58" DAY_SECOND), "Network Issues", "Despite not having legs I tripped over the cord for the router. We should be swimming again momentarily.");
