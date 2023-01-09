FROM lloesche/valheim-server:latest

COPY ./notifyDiscord.sh /bin/notifiyDiscord
COPY ./worldInit.sh /bin/worldInit

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
  unzip awscliv2.zip && \
  ./aws/install

ENV PRE_BOOTSTRAP_HOOK='worldInit $WORLD_BUCKET $WORLD_NAME'
ENV PRE_SERVER_RUN_HOOK='notifiyDiscord "Server starting..."'
ENV POST_SERVER_LISTENING_HOOK='notifiyDiscord "Server now accepting connections at $URL!"'
# ENV PRE_BACKUP_HOOK='notifiyDiscord "About to make a backup..."'
# ENV POST_BACKUP_HOOK='notifiyDiscord "Backup made at @BACKUP_FILE@!"'
ENV PRE_SERVER_SHUTDOWN_HOOK='notifiyDiscord "Server shutting down..."'
ENV POST_SERVER_SHUTDOWN_HOOK='notifiyDiscord "Server dead."'
