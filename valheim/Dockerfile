FROM lloesche/valheim-server:latest
ARG WORLD_NAME

COPY ./notifyDiscord.sh /bin/notifiyDiscord
COPY ./config /config

ENV PRE_SERVER_RUN_HOOK='notifiyDiscord "Server starting..."'
ENV POST_SERVER_LISTENING_HOOK='notifiyDiscord "Server now accepting connections at $URL!"'
# ENV PRE_BACKUP_HOOK='notifiyDiscord "About to make a backup..."'
# ENV POST_BACKUP_HOOK='notifiyDiscord "Backup made at @BACKUP_FILE@!"'
ENV PRE_SERVER_SHUTDOWN_HOOK='notifiyDiscord "Server shutting down..."'
ENV POST_SERVER_SHUTDOWN_HOOK='notifiyDiscord "Server dead."'

ENV WORLD_NAME=${WORLD_NAME}
