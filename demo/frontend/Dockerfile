FROM node:20-alpine as development

WORKDIR /app

# Add a non-root user
RUN addgroup -g 1001 vscode \
    && adduser -u 1001 -G vscode -s /bin/sh -D vscode \
    && mkdir -p /home/vscode/.vscode-server/bin \
    && mkdir -p /home/vscode/.vscode-server/extensions \
    && chown -R vscode:vscode /home/vscode \
    && chown -R vscode:vscode /app

COPY package*.json ./
RUN npm install && \
    mkdir -p /app/node_modules && \
    chown -R vscode:vscode /app/node_modules
# Keep node_modules in the container, not in the mounted volume
ENV NODE_PATH=/app/node_modules

USER vscode

CMD ["npm", "run", "dev"]

FROM node:20-alpine as build
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
# Create index.html if it doesn't exist
RUN mkdir -p public && \
    if [ ! -f public/index.html ]; then \
    echo '<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8" /><link rel="icon" type="image/svg+xml" href="/vite.svg" /><meta name="viewport" content="width=device-width, initial-scale=1.0" /><title>DevContainer Demo App</title></head><body><div id="root"></div><script type="module" src="/src/main.jsx"></script></body></html>' > public/index.html; \
    fi && \
    if [ ! -f public/vite.svg ]; then \
    echo '<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32" fill="none"><rect width="32" height="32" rx="4" fill="#646CFF"/><path d="M16 8L24 16L16 24L8 16L16 8Z" fill="white"/></svg>' > public/vite.svg; \
    fi
RUN npm run build

FROM nginx:alpine as production
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]