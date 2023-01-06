FROM lloesche/valheim-server:latest
ARG WORLD_NAME

COPY ./config /config
ENV POST_START_HOOK='curl -sfSL -X POST -H "Content-Type: application/json" -d "{\"username\":\"Valheim-Bot\",\"content\":\"STARTING SERVER\"}" "$DISCORD_WEBHOOK"'
ENV WORLD_NAME=${WORLD_NAME}
