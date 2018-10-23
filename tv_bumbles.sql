CREATE DATABASE tv_bumble;

CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  username VARCHAR(400),
  password_digest VARCHAR(400)
);  

CREATE TABLE shows (
  id SERIAL PRIMARY KEY,
  show_id VARCHAR(200),
  name VARCHAR(400),
  premiered VARCHAR(200),
  image_url VARCHAR(400),
  summary TEXT
);

CREATE TABLE watches (
  id SERIAL PRIMARY KEY,
  user_id INTEGER,
  show_id INTEGER,
  rating INTEGER
);


INSERT INTO shows (show_id, name, premiered, image_url, summary) VALUES ('427','Buffy the Vampire Slayer', '1997-03-10', 'http://static.tvmaze.com/uploads/images/medium_portrait/2/7490.jpg', 'Into every generation, there is a chosen one. She alone will stand against the vampires, the demons, and the forces of darkness. She is the slayer.\"</i></p><p>Buffy Summers is the latest in a line of young women known as \"Vampire Slayers\" who have to battle vampires, demons and other forces of evil, all while growing up and dealing with love and teenage angst in this iconic cult series. She and her \"Scooby Gang\" fight the good fight in a small town called Sunnydale.');