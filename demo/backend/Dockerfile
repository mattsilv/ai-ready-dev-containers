FROM python:3.11-slim-bookworm as development

WORKDIR /app

RUN apt-get update && apt-get install -y \
    curl \
    build-essential \
    git \
    iputils-ping \
    net-tools \
    procps \
    vim \
    sqlite3 \
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

FROM python:3.11-slim-bookworm as production
WORKDIR /app

RUN apt-get update && apt-get install -y \
    curl \
    sqlite3 \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .

CMD ["gunicorn", "src.main:app", "-w", "4", "-k", "uvicorn.workers.UvicornWorker", "--bind", "0.0.0.0:8000"]