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
RUN npm run build

FROM nginx:alpine as production
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]