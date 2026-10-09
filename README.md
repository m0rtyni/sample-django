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

Configured a custom bridge network (django-network) in Docker Compose to enable communication between Django and PostgreSQL.

Network Types
Bridge: Connects containers on the same Docker host.
Host: Uses the host's network namespace directly.
Overlay: Connects containers across multiple Docker hosts.
None: Disables container networking.

Verification
Both containers successfully connected to django-network.
Docker assigned internal IP addresses to both containers.
Docker DNS successfully resolved db to 172.19.0.2.
Django successfully connected to PostgreSQL using DB_HOST=db.

