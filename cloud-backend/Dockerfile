# RYZONE Cloud Backend container for Google Cloud Run
FROM node:20-slim
ENV NODE_ENV=production
RUN apt-get update && apt-get install -y --no-install-recommends ffmpeg \
  && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY package.json ./
RUN npm install --omit=dev --no-audit --no-fund && npm cache clean --force
COPY src ./src
USER node
EXPOSE 8080
CMD ["node", "src/server.js"]
