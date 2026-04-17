
# mt5Docker

## Build Container

### Prerequisites
- Docker installed on your system
- Access to the Dockerfile in this directory

### Build Instructions

1. **Navigate to the project directory:**
    ```bash
    cd /D:/docketTrader/docker/mt5Docker
    ```

2. **Build the Docker image:**
    ```bash
    docker build --no-cache -t mt5-beq-auto:latest .
    ```

3. **Verify the build:**
    ```bash
    docker images | grep mt5-beq-auto
    ```

### Running the Container

```bash
docker run -d --name mt5-container mt5-beq-auto:latest <account> <password> <server>
```

**Example:**
```bash
docker run -d --name mt5_bot_200217359 mt5-beq-auto 200217359 mypassword ECMarketsLtd-Demo02
```

### Running with Python

```python
import subprocess

def start_mt5_container(account: str, password: str, server: str) -> str:
    container_name = f"mt5_bot_{account}"
    cmd = [
        "docker", "run", "-d",
        "--name", container_name,
        "mt5-beq-auto",
        account,
        password,
        server,
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(f"MT5 docker failed: {result.stderr.strip()}")
    return result.stdout.strip()
```

**Usage:**
```python
container_id = start_mt5_container("200217359", "mypassword", "ECMarketsLtd-Demo02")
print(f"Container started: {container_id}")
```

### Cappute image

```bash
import -display :99 -window root /app/screenshot.png
```

### Build Options

- **Tag with version:**
  ```bash
  docker build -t mt5-beq-auto:v1.0 .
  ```

- **Build with no cache:**
  ```bash
  docker build --no-cache -t mt5-beq-auto:latest .
  ```

### Troubleshooting

- Check Dockerfile syntax: `docker build --help`
- View build logs: `docker logs mt5-container`
- Inspect image details: `docker inspect mt5-beq-auto:latest`
- If Wine reports `Bad EXE format for Z:\app\mt5\terminal64.exe`, rebuild the image after the 64-bit Wine prefix change: `docker build --no-cache -t mt5-beq-auto:latest .`



