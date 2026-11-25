FROM node:22-alpine
WORKDIR /app
COPY server/package.json ./server/
RUN cd server && npm install --omit=dev
COPY server/*.mjs ./server/
COPY game/assets/maps.json ./game/assets/maps.json
ENV PORT=8080 DATA_DIR=/data
EXPOSE 8080
VOLUME ["/data"]
CMD ["node","server/index.mjs"]
