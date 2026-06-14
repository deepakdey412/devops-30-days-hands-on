# Essential Docker Commands for DevOps Engineers

## 📑 Table of Contents

1. [Container Management](#.container-management)
2. [Container Logs & Inspection](#.container-logs-inspection)
3. [Container Interaction](#.container-interaction)
4. [Image Management](#.image-management)
5. [Volume Management](#.volume-management)
6. [Network Management](#.network-management)
7. [Docker Compose](#.docker-compose)
8. [Cleanup & Maintenance](#.cleanup-maintenance)
9. [Real-Life Troubleshooting Scenarios](#.real-life-troubleshooting-scenarios)

---

## 🐳 Container Management

| Command                                             | Use                       | Real-Life Example                                                    |
| :-------------------------------------------------- | :------------------------ | :------------------------------------------------------------------- |
| `docker run image`                                  | Create & start container  | `docker run -d nginx:latest` → Start nginx detached [^1][^2]         |
| `docker run -d image`                               | Run detached (background) | `docker run -d --name app python:3.11` → Background app [^2]         |
| `docker run --name name image`                      | Named container           | `docker run --name webserver nginx` → Easy to reference [^2]         |
| `docker start container`                            | Start existing container  | `docker start webserver` → Restart stopped container [^2]            |
| `docker stop container`                             | Stop container (SIGTERM)  | `docker stop webserver` → Graceful stop [^1][^2]                     |
| `docker stop -t 30 container`                       | Stop with timeout         | `docker stop -t 30 app` → 30s timeout before kill [^2]               |
| `docker restart container`                          | Restart container         | `docker restart webserver` → Quick restart after failure [^2]        |
| `docker kill container`                             | Force kill container      | `docker kill app` → Immediate stop (SIGKILL) [^1][^2]                |
| `docker rm container`                               | Remove container          | `docker rm old_app` → Delete stopped container [^1][^2]              |
| `docker rm -f container`                            | Force remove running      | `docker rm -f broken_app` → Kill + remove [^1]                       |
| `docker ps`                                         | List running containers   | `docker ps` → See what's running [^1][^2]                            |
| `docker ps -a`                                      | List all containers       | `docker ps -a` → Include stopped/exited [^2]                         |
| `docker ps -q`                                      | List only IDs             | `docker ps -q` → Get IDs for scripts [^1]                            |
| `docker ps --filter "status=exited"`                | Filter by status          | `docker ps --filter "status=exited"` → Find dead containers [^1]     |
| `docker ps --format "table {{.Name}}\t{{.Status}}"` | Custom output             | `docker ps --format "table {{.Name}} {{.Status}}"` → Clean view [^1] |

---

## 📖 Container Logs & Inspection

| Command                                         | Use                    | Real-Life Example                                               |
| :---------------------------------------------- | :--------------------- | :-------------------------------------------------------------- |
| `docker logs container`                         | Show container logs    | `docker logs app` → See application output [^1][^2]             |
| `docker logs -f container`                      | Follow logs live       | `docker logs -f app` → Monitor in real-time [^1][^2]            |
| `docker logs --tail 100 container`              | Last 100 lines         | `docker logs --tail 500 app` → Recent errors only [^1]          |
| `docker logs -t container`                      | Show timestamps        | `docker logs -t app` → See when errors occurred [^1]            |
| `docker inspect container`                      | Detailed info          | `docker inspect app` → Get IP, config, env vars [^1]            |
| `docker inspect -f "{{.State.IP}}" container`   | Extract specific field | `docker inspect -f "{{.State.IP}}" app` → Get container IP [^1] |
| `docker inspect -f "{{.Config.Env}}" container` | Show environment       | `docker inspect -f "{{.Config.Env}}" app` → Check env vars [^1] |
| `docker top container`                          | Show processes inside  | `docker top app` → See what's running inside [^1]               |
| `docker stats container`                        | Live resource usage    | `docker stats app` → CPU/memory in real-time [^1]               |
| `docker stats --no-stream`                      | One-time stats         | `docker stats --no-stream` → Quick snapshot [^1]                |

---

## 🔍 Container Interaction

| Command                         | Use                 | Real-Life Example                                      |
| :------------------------------ | :------------------ | :----------------------------------------------------- |
| `docker exec container cmd`     | Run command inside  | `docker exec app python test.py` → Run script [^1][^2] |
| `docker exec -it container cmd` | Interactive mode    | `docker exec -it app python` → Enter Python shell [^1] |
| `docker exec -d container cmd`  | Detached exec       | `docker exec -d app backup.sh` → Background task [^1]  |
| `docker attach container`       | Attach stdin/stdout | `docker attach app` → Connect to running process [^1]  |
| `docker cp src dest`            | Copy files          | `docker cp config.yaml app:/etc/` → Add config [^1]    |
| `docker cp container:src local` | Copy from container | `docker cp app:/var/log/app.log .` → Get logs out [^1] |

---

## 🏗️ Image Management

| Command                      | Use                         | Real-Life Example                                            |
| :--------------------------- | :-------------------------- | :----------------------------------------------------------- |
| `docker images`              | List all images             | `docker images` → See downloaded images [^1][^2]             |
| `docker images -q`           | List only IDs               | `docker images -q` → Get IDs for cleanup [^1]                |
| `docker pull image`          | Download image              | `docker pull nginx:1.25` → Get specific version [^1][^2]     |
| `docker pull -q image`       | Quiet pull                  | `docker pull -q python:3.11` → Less output [^1]              |
| `docker build -t name .`     | Build image from Dockerfile | `docker build -t myapp .` → Create app image [^1][^2]        |
| `docker build -t name:tag .` | Build with tag              | `docker build -t myapp:v1.2 .` → Version your image [^1]     |
| `docker build --no-cache .`  | Build without cache         | `docker build --no-cache .` → Fresh build [^1]               |
| `docker push image`          | Upload to registry          | `docker push myapp:v1` → Deploy to Docker Hub [^1]           |
| `docker tag src dst`         | Tag image                   | `docker tag myapp:v1 myuser/myapp:v1` → Rename for push [^1] |
| `docker rmi image`           | Remove image                | `docker rmi nginx:old` → Delete old image [^1][^2]           |
| `docker rmi -f image`        | Force remove                | `docker rmi -f broken` → Remove even if used [^1]            |
| `docker image prune`         | Remove unused images        | `docker image prune` → Clean dangling images [^1]            |
| `docker image prune -a`      | Remove all unused           | `docker image prune -a` → Full cleanup [^1]                  |
| `docker history image`       | Show image layers           | `docker history myapp` → See build steps [^1]                |
| `docker save -o file image`  | Save image to file          | `docker save -o app.tar myapp` → Offline transfer [^1]       |
| `docker load -i file`        | Load image from file        | `docker load -i app.tar` → Restore from backup [^1]          |

---

## 📦 Volume Management

| Command                                                 | Use            | Real-Life Example                                                            |
| :------------------------------------------------------ | :------------- | :--------------------------------------------------------------------------- |
| `docker volume create name`                             | Create volume  | `docker volume create db_data` → Persistent storage [^1][^2]                 |
| `docker volume ls`                                      | List volumes   | `docker volume ls` → See all volumes [^1][^2]                                |
| `docker volume rm name`                                 | Remove volume  | `docker volume rm old_data` → Delete unused [^1]                             |
| `docker volume inspect name`                            | Volume details | `docker volume inspect db_data` → Get mount path [^1]                        |
| `docker run -v vol:path image`                          | Mount volume   | `docker run -v db_data:/var/lib/mysql mysql` → DB storage [^2]               |
| `docker run -v path:path image`                         | Bind mount     | `docker run -v ./config:/etc app` → Local config [^1][^2]                    |
| `docker run --mount type=volume,src=vol,dst=path image` | Modern mount   | `docker run --mount type=volume,src=db_data,dst=/data mysql` → Explicit [^1] |

---

## 🌐 Network Management

| Command                                 | Use                | Real-Life Example                                                |
| :-------------------------------------- | :----------------- | :--------------------------------------------------------------- |
| `docker network ls`                     | List networks      | `docker network ls` → See custom networks [^1][^2]               |
| `docker network create name`            | Create network     | `docker network create backend` → Isolate services [^1][^2]      |
| `docker network rm name`                | Remove network     | `docker network rm old_net` → Delete unused [^1]                 |
| `docker network inspect name`           | Network details    | `docker network inspect backend` → See connected containers [^1] |
| `docker run --network name image`       | Connect to network | `docker run --network backend app` → Join network [^1][^2]       |
| `docker run -p host:container image`    | Port mapping       | `docker run -p 8080:80 nginx` → Access via 8080 [^1][^2]         |
| `docker run -p 127.0.0.1:8080:80 image` | Local-only port    | `docker run -p 127.0.0.1:8080:80 nginx` → Secure binding [^1]    |
| `docker run --port 8080 image`          | Random host port   | `docker run --port 8080 app` → Auto port assignment [^1]         |

---

## 🔧 Docker Compose

| Command                       | Use                     | Real-Life Example                                       |
| :---------------------------- | :---------------------- | :------------------------------------------------------ |
| `docker-compose up`           | Start all services      | `docker-compose up` → Launch stack [^1][^2]             |
| `docker-compose up -d`        | Start detached          | `docker-compose up -d` → Background services [^1][^2]   |
| `docker-compose up --build`   | Build + start           | `docker-compose up --build` → Rebuild images [^1][^2]   |
| `docker-compose down`         | Stop all services       | `docker-compose down` → Clean shutdown [^1][^2]         |
| `docker-compose down -v`      | Stop + remove volumes   | `docker-compose down -v` → Full reset [^1]              |
| `docker-compose restart`      | Restart services        | `docker-compose restart app` → Refresh service [^1]     |
| `docker-compose ps`           | List compose services   | `docker-compose ps` → See running stack [^1]            |
| `docker-compose logs`         | Show all logs           | `docker-compose logs` → View entire stack [^1]          |
| `docker-compose logs -f app`  | Follow specific service | `docker-compose logs -f app` → Monitor app [^1]         |
| `docker-compose exec app cmd` | Run in service          | `docker-compose exec app python test.py` → Execute [^1] |
| `docker-compose build`        | Build only              | `docker-compose build` → Pre-build images [^1]          |
| `docker-compose config`       | Show config             | `docker-compose config` → Verify YAML [^1]              |

---

## 🧹 Cleanup & Maintenance

| Command                  | Use                       | Real-Life Example                                     |
| :----------------------- | :------------------------ | :---------------------------------------------------- |
| `docker system prune`    | Remove unused data        | `docker system prune` → Clean stopped containers [^1] |
| `docker system prune -a` | Aggressive cleanup        | `docker system prune -a` → Remove all unused [^1]     |
| `docker container prune` | Remove stopped containers | `docker container prune` → Cleanup exited [^1]        |
| `docker volume prune`    | Remove unused volumes     | `docker volume prune` → Delete orphan volumes [^1]    |
| `docker info`            | System info               | `docker info` → Check disk usage, version [^1]        |
| `docker version`         | Docker version            | `docker version` → Verify installation [^1]           |

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

## 📚 References

[^1]: [100 Linux Commands for DevOps Engineers - Medium](https://medium.com/@rajkumarsingh07/100-linux-commands-that-need-to-be-used-for-devops-engineers-linux-administrator-and-cloud-engineer-294f9508f030)

[^2]: [30 Essential Linux Commands for DevOps - LinkedIn](https://www.linkedin.com/posts/ansh-narayan-pandey_devops-linux-sysadmin-activity-7397239184412983297-ZPHx)

---

<div align="center">
**These are the exact Docker commands used daily by senior DevOps engineers in production environments**
</div>
