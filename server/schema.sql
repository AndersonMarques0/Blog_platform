CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    username VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    avatar VARCHAR(255) NOT NULL
);

CREATE TABLE blogs (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    user_id INT REFERENCES users(id),
    read_time INT,
    tags TEXT[],
    created TIMESTAMP DEFAULT NOW()
);

CREATE TABLE likes (
    like_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(id),
    blog_id INT REFERENCES blogs(id),
    UNIQUE(user_id, blog_id)
);

CREATE TABLE comments (
    id SERIAL PRIMARY KEY,
    users_id INT REFERENCES users(id),
    blog_id INT REFERENCES blogs(id),
    content TEXT NOT NULL,
    created TIMESTAMP DEFAULT NOW()
);
