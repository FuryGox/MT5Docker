
# mt5Docker

## Build Container

### Setup
Folder `mt5_source` is MT5 app, it need some config before being build to docker images
File `entrypoint.sh` is where you can change web url for Expert Advisors to work, and change Expert Advisors file path

1. **Setup MT5**

    a. Setup Expert Advisors
    - Open path ``mt5_source\MQL5\Experts\Advisors``
    - Copy your Expert Advisors to that folder 
    - Setup entrypoint to point Expert to that file (see how in Setup entrypoint -> Setup Login File)
    - Then you need to open MT5 in portable mode to confirm it append in Expert Advisors at left side panel (you may need to refresh it)

    b. Config Broker Server IP

    - Open Command Prompt inside mt5_source or use 
    ```bash
    cd path_to_project/mt5_source
    ```

    - Then use this command to run it in portable mode
    ```bash
    terminal64.exe /portable
    ```

    - Then you can add more server by `` open a new account -> enter name of your broker -> let it scan`` after that it will add server ip to some config file in ``mt5_source``. You can scan how many borker server you want



2. **Setup entrypoint**
    
    a. Setup Login File
    - Open entrypoint.sh file 
    - From ``Create the login configuration file for MT5`` line
    - Change Expert=Advisors\lumir-mt5 to Advisors\your_EA_file
    - Change Symbol=XAUUSD to your markets you want, some broker name it different like XAUUSDt or some thing you may need to check that
    
    - Other setting you can lookup at ``https://www.metatrader5.com/en/terminal/help/start_advanced/start#configuration_file`` and add to file

    b. Change web-url 
    - Open entrypoint.sh file at line 138
    - Change "https://example.com/your-advisors-url" to your EA url if need


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
docker run -d --name mt5-container mt5-beq-auto:latest <account> <password> <server> [url]
```

**Example:**
```bash
docker run -d --name mt5_bot_200217359 mt5-beq-auto 200217359 mypassword ECMarketsLtd-Demo02
```

### Running with Python

```python
import subprocess

def start_mt5_container(account: str, password: str, server: str, url: str | None = None) -> str:
    container_name = f"mt5_bot_{account}"
    cmd = [
        "docker", "run", "-d",
        "--name", container_name,
        "mt5-beq-auto",
        account,
        password,
        server,
    ]
    if url:
        cmd.append(url)
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(f"MT5 docker failed: {result.stderr.strip()}")
    return result.stdout.strip()
```

**Usage:**
```python
container_id = start_mt5_container(
    "200217359",
    "mypassword",
    "ECMarketsLtd-Demo02",
    "https://example.com/webhook",
)
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



