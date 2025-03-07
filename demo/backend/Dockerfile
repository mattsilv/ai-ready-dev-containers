FROM python:3.13.2-slim-bookworm as development

WORKDIR /app

RUN apt-get update && apt-get install -y \
    curl=7.88.1-10+deb12u5 \
    build-essential=12.9 \
    git=1:2.39.2-1.1 \
    iputils-ping=3:20221126-1 \
    net-tools=2.10-0.1 \
    procps=2:4.0.2-3 \
    vim=2:9.0.1378-2 \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user
RUN groupadd --gid 1000 vscode \
    && useradd --uid 1000 --gid 1000 -m vscode \
    && mkdir -p /home/vscode/.vscode-server/bin \
    && mkdir -p /home/vscode/.vscode-server/extensions \
    && chown -R vscode:vscode /home/vscode \
    && chown -R vscode:vscode /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Development stage doesn't need CMD as it's specified in docker-compose.yml

FROM python:3.13.2-slim-bookworm as production
WORKDIR /app

RUN apt-get update && apt-get install -y \
    curl=7.88.1-10+deb12u5 \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .

CMD ["gunicorn", "src.main:app", "-w", "4", "-k", "uvicorn.workers.UvicornWorker", "--bind", "0.0.0.0:8000"]