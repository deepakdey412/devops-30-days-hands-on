# Essential Docker Commands for DevOps Engineers

## 📑 Table of Contents

1. [Container Management](#container-management)
2. [Container Logs and Inspection](#container-logs-and-inspection)
3. [Container Interaction](#container-interaction)
4. [Image Management](#image-management)
5. [Volume Management](#volume-management)
6. [Network Management](#network-management)
7. [Docker Compose](#docker-compose)
8. [Cleanup and Maintenance](#cleanup-and-maintenance)
9. [Real-Life Troubleshooting Scenarios](#real-life-troubleshooting-scenarios)

---

## 🐳 Container Management

| Command                                          | Use                        | Real-Life Example                                             |
| :----------------------------------------------- | :------------------------- | :------------------------------------------------------------ |
| docker run image                                 | Create and start container | docker run -d nginx:latest → Start nginx detached             |
| docker run -d image                              | Run detached (background)  | docker run -d --name app python:3.11 → Background app         |
| docker run --name name image                     | Named container            | docker run --name webserver nginx → Easy to reference         |
| docker start container                           | Start existing container   | docker start webserver → Restart stopped container            |
| docker stop container                            | Stop container (SIGTERM)   | docker stop webserver → Graceful stop                         |
| docker stop -t 30 container                      | Stop with timeout          | docker stop -t 30 app → 30s timeout before kill               |
| docker restart container                         | Restart container          | docker restart webserver → Quick restart after failure        |
| docker kill container                            | Force kill container       | docker kill app → Immediate stop (SIGKILL)                    |
| docker rm container                              | Remove container           | docker rm old_app → Delete stopped container                  |
| docker rm -f container                           | Force remove running       | docker rm -f broken_app → Kill + remove                       |
| docker ps                                        | List running containers    | docker ps → See what's running                                |
| docker ps -a                                     | List all containers        | docker ps -a → Include stopped/exited                         |
| docker ps -q                                     | List only IDs              | docker ps -q → Get IDs for scripts                            |
| docker ps --filter "status=exited"               | Filter by status           | docker ps --filter "status=exited" → Find dead containers     |
| docker ps --format "table {{.Name}} {{.Status}}" | Custom output              | docker ps --format "table {{.Name}} {{.Status}}" → Clean view |

---

## 📖 Container Logs and Inspection

| Command                                       | Use                   | Real-Life Example                                        |
| :-------------------------------------------- | :-------------------- | :------------------------------------------------------- |
| docker logs container                         | Show container logs   | docker logs app → See application output                 |
| docker logs -f container                      | Follow logs live      | docker logs -f app → Monitor in real-time                |
| docker logs --tail 100 container              | Last 100 lines        | docker logs --tail 500 app → Recent errors only          |
| docker logs -t container                      | Show timestamps       | docker logs -t app → See when errors occurred            |
| docker inspect container                      | Detailed info         | docker inspect app → Get IP, config, env vars            |
| docker inspect -f "{{.State.IP}}" container   | Extract IP            | docker inspect -f "{{.State.IP}}" app → Get container IP |
| docker inspect -f "{{.Config.Env}}" container | Show environment      | docker inspect -f "{{.Config.Env}}" app → Check env vars |
| docker top container                          | Show processes inside | docker top app → See running processes                   |
| docker stats container                        | Live resource usage   | docker stats app → CPU/memory real-time                  |
| docker stats --no-stream                      | One-time stats        | docker stats --no-stream → Quick snapshot                |

---

## 🔍 Container Interaction

| Command                       | Use                 | Real-Life Example                               |
| :---------------------------- | :------------------ | :---------------------------------------------- |
| docker exec container cmd     | Run command inside  | docker exec app python test.py → Run script     |
| docker exec -it container cmd | Interactive mode    | docker exec -it app python → Enter Python shell |
| docker exec -d container cmd  | Detached exec       | docker exec -d app backup.sh → Background task  |
| docker attach container       | Attach stdin/stdout | docker attach app → Connect to process          |
| docker cp src dest            | Copy files          | docker cp config.yaml app:/etc/ → Add config    |
| docker cp container:src local | Copy from container | docker cp app:/var/log/app.log . → Get logs out |

---

## 🏗️ Image Management

| Command                    | Use                   | Real-Life Example                                     |
| :------------------------- | :-------------------- | :---------------------------------------------------- |
| docker images              | List all images       | docker images → See downloaded images                 |
| docker images -q           | List only IDs         | docker images -q → Get IDs for cleanup                |
| docker pull image          | Download image        | docker pull nginx:1.25 → Get specific version         |
| docker pull -q image       | Quiet pull            | docker pull -q python:3.11 → Less output              |
| docker build -t name .     | Build from Dockerfile | docker build -t myapp . → Create app image            |
| docker build -t name:tag . | Build with tag        | docker build -t myapp:v1.2 . → Version your image     |
| docker build --no-cache .  | Build without cache   | docker build --no-cache . → Fresh build               |
| docker push image          | Upload to registry    | docker push myapp:v1 → Deploy to Docker Hub           |
| docker tag src dst         | Tag image             | docker tag myapp:v1 myuser/myapp:v1 → Rename for push |
| docker rmi image           | Remove image          | docker rmi nginx:old → Delete old image               |
| docker rmi -f image        | Force remove          | docker rmi -f broken → Remove even if used            |
| docker image prune         | Remove unused images  | docker image prune → Clean dangling images            |
| docker image prune -a      | Remove all unused     | docker image prune -a → Full cleanup                  |
| docker history image       | Show image layers     | docker history myapp → See build steps                |
| docker save -o file image  | Save image to file    | docker save -o app.tar myapp → Offline transfer       |
| docker load -i file        | Load image from file  | docker load -i app.tar → Restore from backup          |

---

## 📦 Volume Management

| Command                                               | Use            | Real-Life Example                                                     |
| :---------------------------------------------------- | :------------- | :-------------------------------------------------------------------- |
| docker volume create name                             | Create volume  | docker volume create db_data → Persistent storage                     |
| docker volume ls                                      | List volumes   | docker volume ls → See all volumes                                    |
| docker volume rm name                                 | Remove volume  | docker volume rm old_data → Delete unused                             |
| docker volume inspect name                            | Volume details | docker volume inspect db_data → Get mount path                        |
| docker run -v vol:path image                          | Mount volume   | docker run -v db_data:/var/lib/mysql mysql → DB storage               |
| docker run -v path:path image                         | Bind mount     | docker run -v ./config:/etc app → Local config                        |
| docker run --mount type=volume,src=vol,dst=path image | Modern mount   | docker run --mount type=volume,src=db_data,dst=/data mysql → Explicit |

---

## 🌐 Network Management

| Command                               | Use                | Real-Life Example                                         |
| :------------------------------------ | :----------------- | :-------------------------------------------------------- |
| docker network ls                     | List networks      | docker network ls → See custom networks                   |
| docker network create name            | Create network     | docker network create backend → Isolate services          |
| docker network rm name                | Remove network     | docker network rm old_net → Delete unused                 |
| docker network inspect name           | Network details    | docker network inspect backend → See connected containers |
| docker run --network name image       | Connect to network | docker run --network backend app → Join network           |
| docker run -p host:container image    | Port mapping       | docker run -p 8080:80 nginx → Access via 8080             |
| docker run -p 127.0.0.1:8080:80 image | Local-only port    | docker run -p 127.0.0.1:8080:80 nginx → Secure binding    |
| docker run --port 8080 image          | Random host port   | docker run --port 8080 app → Auto port assignment         |

---

## 🔧 Docker Compose

| Command                     | Use                     | Real-Life Example                                |
| :-------------------------- | :---------------------- | :----------------------------------------------- |
| docker-compose up           | Start all services      | docker-compose up → Launch stack                 |
| docker-compose up -d        | Start detached          | docker-compose up -d → Background services       |
| docker-compose up --build   | Build + start           | docker-compose up --build → Rebuild images       |
| docker-compose down         | Stop all services       | docker-compose down → Clean shutdown             |
| docker-compose down -v      | Stop + remove volumes   | docker-compose down -v → Full reset              |
| docker-compose restart      | Restart services        | docker-compose restart app → Refresh service     |
| docker-compose ps           | List compose services   | docker-compose ps → See running stack            |
| docker-compose logs         | Show all logs           | docker-compose logs → View entire stack          |
| docker-compose logs -f app  | Follow specific service | docker-compose logs -f app → Monitor app         |
| docker-compose exec app cmd | Run in service          | docker-compose exec app python test.py → Execute |
| docker-compose build        | Build only              | docker-compose build → Pre-build images          |
| docker-compose config       | Show config             | docker-compose config → Verify YAML              |

---

## 🧹 Cleanup and Maintenance

| Command                | Use                       | Real-Life Example                              |
| :--------------------- | :------------------------ | :--------------------------------------------- |
| docker system prune    | Remove unused data        | docker system prune → Clean stopped containers |
| docker system prune -a | Aggressive cleanup        | docker system prune -a → Remove all unused     |
| docker container prune | Remove stopped containers | docker container prune → Cleanup exited        |
| docker volume prune    | Remove unused volumes     | docker volume prune → Delete orphan volumes    |
| docker info            | System info               | docker info → Check disk usage, version        |
| docker version         | Docker version            | docker version → Verify installation           |

---

## 🚀 Real-Life Troubleshooting Scenarios

### Scenario 1: Container won't start

```bash
docker ps -a --filter "status=exited"          # Find dead containers
docker inspect broken_container                # Check error reason
docker logs broken_container --tail 50         # See last 50 log lines
```

### Scenario 2: High CPU usage

```bash
docker stats                                    # Live CPU/memory for all
docker stats --no-stream app                    # One-time snapshot
docker top app                                  # Processes inside container
```

### Scenario 3: Disk full

```bash
docker system prune -a                        # Clean everything unused
docker images -q | xargs docker rmi           # Remove all images
docker volume prune                            # Remove orphan volumes
```

### Scenario 4: Port conflict

```bash
docker ps --filter "network=host"             # Find containers on port
docker inspect app --format '{{.NetworkSettings.IPAddress}}'  # Get IP
```

### Scenario 5: Deploy to production

```bash
docker build -t myapp:v1.2 .                  # Build with version
docker tag myapp:v1.2 registry.com/myapp:v1.2 # Tag for registry
docker push registry.com/myapp:v1.2           # Upload
docker run -d --name app -p 8080:80 registry.com/myapp:v1.2  # Deploy
```

---

## 📚 How to Use This File

1. **Copy** full content above
2. **Paste** into Notepad or VS Code
3. **Save** as `docker-commands.md`
4. **Open** in VS Code (Ctrl+Shift+V for preview) OR GitHub.com

---

## ✔️ These are the exact Docker commands used daily by senior DevOps engineers

---

<div align="center">
**END OF FILE**
</div>
