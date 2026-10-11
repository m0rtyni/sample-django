    Task 1: Docker Image Optimization
Optimized the Django application's Docker image using a multi-stage build.

Improvements:
1. python:3.13-slim as the base image.
2. Separated build dependencies from runtime dependencies.
3. Configured the application to run as a non-root user
4. Improved build caching

-----Before-----
django-app:v1.2   9a068f5a22a2        458MB          103MB  
    Build Time:
real    5m15.040s
user    0m0.101s
sys     0m0.248s

-----After-----
django-app:v1.3   caacfea6dd8f        360MB         82.1MB   
    Build Time:
real    5m10.103s
user    0m0.043s
sys     0m0.228s

-----Cache build-----
    Build Time:
real    0m6.097s
user    0m0.010s
sys     0m0.000s

    Task 2: Implementing Docker Compose for Local Development
Configured Docker Compose to run the Django application with PostgreSQL.

Configuration:
1. web - Django application run from dockerfile.
2. db - PostgreSQL 17 Database
3. Network - communication between containers.
4. Volume - Persistent PostgreSQL storage.
5. Healthcheck - waits for the database to become ready.

    Task 3: Understanding Docker Networking

Docker network types:
1. Bridge - default network driver, connect containers to the same Docker host.
2. Host - remove network isolation between the containers and the Docker host.
3. Overlay - Connects containers across multiple Docker hosts.
4. None - Fully isolated container from networking.
5. Ipvlan - Connect containers to external VLANs.
6. Macvlan -  Gives containers their own MAC addresses, making them appear as separate devices on the physical network.

- Bridge network 

Docker Compose setup runs two services:
1. web - the django application, exposed to port 8000.
2. db - PostreSQL, accessible internaly on port 5432.

Both services use the user-defined bridge network django-network. The application connects to PostgreSQL using DB_HOST=db.

$:docker compose ps
sample-django-db-1 - Up 57 minutes (healthy) - 5432/tcp
sample-django-web-1 - Up 57 minutes - 0.0.0.0:8000->8000/tcp, [::]:8000->8000/tcp

$:docker compose exec web python -c "import socket; print(socket.gethostbyname('db'))"
172.19.0.2

- Host network

Run a temporary Alpine container using the host network:
$:docker run --rm --network host alpine:latest ip addr
Command displays the network interfaces visible in this environment. The test showed the eth0 interface with IP address.

- Overlay network

Create an attachable overlay network and a test container:
$:docker swarm init
$:docker network create --driver overlay --attachable --subnet 10.0.1.0/24 test-overlay
$:docker run -d --name overlay-server --network test-overlay alpine:latest sleep 600
$:docker inspect overlay-server --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'

Test connectivity:
$:docker run --rm --network test-overlay alpine:latest ping -c 4 <OVERLAY_SERVER_IP>

Result:
--- 10.0.1.7 ping statistics ---
4 packets transmitted, 4 packets received, 0% packet loss
round-trip min/avg/max = 0.049/0.070/0.113 ms
