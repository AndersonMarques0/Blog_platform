# Blog Platform

A full-stack blog platform where users can create, edit and delete blog posts, like posts and leave comments.

## Tech Stack

- **Frontend:** React, TypeScript, Tailwind CSS
- **Backend:** Node.js, Express
- **Database:** PostgreSQL
- **Editor:** TipTap

## Features

- Register and login
- Create, edit and delete blog posts with rich text editor
- Like and unlike posts
- Add and delete comments
- Responsive design

## Installation

### Prerequisites
- Node.js
- PostgreSQL

### Backend
```bash
cd server
npm install
node index.js
```

### Frontend
```bash
npm install
npm run dev
```

### Database
Create a PostgreSQL database called `blog_platform` and run the following tables:
```sql
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
```

[Live Demo](https://blog-platform-1-94qc.onrender.com/)

The commands below will be write in Bash.

# Use docker to execute the project

## 1. Install Docker
[Instalar Docker Engine](https://docs.docker.com/engine/install/)
[Instalar Docker Compose](https://docs.docker.com/compose/install/)

Check the installation
```
docker --version
docker compose version
docker info
```

## 2. Crie os arquivos .env
At the root folder
.env
POSTGRES_DB=blog_platform
POSTGRES_USER=blog_user
POSTGRES_PASSWORD=senha
.env.developmento
VITE_API_URL=http://localhost:3001
At server/.env
CLOUDINARY_CLOUD_NAME=valor
CLOUDINARY_API_KEY=valor
CLOUDINARY_API_SECRET=valor

## 3. Check the configuration
The file docker-swarm/compose.yaml must set three services:
- manager: manage the inner Swarm.
- worker1: first node of work.
- worker2: second node of work.

The setup uses a brigde network with fixed addresses:
| Container | Inner Address |
| --- | --- |
| manager | 172.30.250.10 |
| worker 1 | 172.30.250.11 |
| worker 2 | 172.30.250.12 |

Validate the setup:
``
docker compose -f docker-swarm/compose.yaml config --quiet
``

## 4. Start the DinD containers
Run this command from root folder:
`` 
docker compose -f docker-swarm/compose.yaml up -d
``
Check the containers' state:
``
docker compose -f docker-swarm/compose.yaml ps
``
Published ports in the computer
| Host Port | Role |
| --- | --- |
| 23750 | API Docker from inner manager |
| 8081 | Visualizer from inner Swarm |
| 8083 | DinD's Frontend |

## 5. Start the inner Swarm
These commands must be ran only in the first setup of new cluster.
Set the variable that identify the inner docker:
``
INNER_DOCKER="tcp://127.0.0.1:23750"
``

Check the state
```
docker -H "$INNER_DOCKER" info \
  --format 'Node={{.Name}} Swarm={{.Swarm.LocalNodeState}}'
```

If the state is inactive, start the manager
```
docker -H "$INNER_DOCKER" swarm init \
  --advertise-addr 172.30.250.10
```

Get the entry token from workers
``
WORKER_TOKEN=$(docker -H "$INNER_DOCKER" swarm join-token -q worker)
``

Run these commands only for workers that don't belong to cluster
``
docker exec docker-swarm-worker1-1 \
  docker -H tcp://127.0.0.1:2375 swarm join \
  --token "$WORKER_TOKEN" 172.30.250.10:2377

docker exec docker-swarm-worker2-1 \
  docker -H tcp://127.0.0.1:2375 swarm join \
  --token "$WORKER_TOKEN" 172.30.250.10:2377
``

Check the cluster
``
docker -H "$INNER_DOCKER" node ls
``

# 6. Get ready the variables for deploy
At root folder
```
set -a
source .env
source <(grep -E '^(CLOUDINARY_CLOUD_NAME|CLOUDINARY_API_KEY|CLOUDINARY_API_SECRET)=' server/.env)
set +a
```
Check the stack.yaml
``
docker stack config -c stack.yaml >/dev/null
``

# 7. Install DinD
stack.yaml must have:
- frontend: published at inner port 8082.
- api: connected to database.
- db: persistent volume with PostgreSQL.
- visualizer: published at inner port 8080.

Create the replicas:
```
API_REPLICAS=1 docker -H "$INNER_DOCKER" stack deploy \
  --resolve-image always \
  -c stack.yaml blog-platform-dind
```

Check the services:
``
docker -H "$INNER_DOCKER" stack services blog-platform-dind
``

# Create the PostgreSQL tables
Find the PostgreSQL container at DinD:
```
DB_ID=$(docker -H "$INNER_DOCKER" ps \
  --filter label=com.docker.swarm.service.name=blog-platform-dind_db \
  --filter status=running \
  -q | head -n 1)

if [[ -z "$DB_ID" ]]; then
  echo "PostgreSQL não está em execução."
  exit 1
fi
```

Before to apply the SQL, chech if the tables exists:
```
docker -H "$INNER_DOCKER" exec "$DB_ID" sh -lc \
  'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "\dt"'
```

If the database is empty of tables, apply the schema once:
```
docker -H "$INNER_DOCKER" exec -i "$DB_ID" sh -lc \
  'psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB"' \
  < server/schema.sql
```

Confirm the creation
```
docker -H "$INNER_DOCKER" exec "$DB_ID" sh -lc \
  'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "\dt"'
```

# 8. Try the application
Open in the browser:
- Frontend DinD: http:localhost:8083
- Docker Visualizer DinD: http://localhost:8081

Try in the terminal:
```
curl -i http://localhost:8083/
curl -i http://localhost:8083/api/blogs
```
