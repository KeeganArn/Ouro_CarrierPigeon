CREATE TABLE IF NOT EXISTS `carrier_pigeon_owners` (
  `charid` INT PRIMARY KEY,
  `pigeon_id` VARCHAR(10) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS `carrier_pigeon_messages` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `recipient_pigeon_id` VARCHAR(10) NOT NULL,
  `sender_pigeon_id` VARCHAR(10),
  `message` TEXT,
  `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO items (item, label, weight, usable) VALUES
('carrier_pigeon', 'Carrier Pigeon', 1.0, 1),
('paper', 'Paper', 0.1, 1),
('pen', 'Pen', 0.2, 1);

CREATE TABLE IF NOT EXISTS carrier_pigeon_training (
    id INT AUTO_INCREMENT PRIMARY KEY,
    pigeon_id VARCHAR(255) NOT NULL,
    location_name VARCHAR(100) NOT NULL,
    coords_x FLOAT NOT NULL,
    coords_y FLOAT NOT NULL,
    coords_z FLOAT NOT NULL
);
