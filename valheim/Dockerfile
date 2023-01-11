FROM lloesche/valheim-server:latest

COPY ./notifyDiscord.sh /bin/notifiyDiscord
COPY ./worldInit.sh /bin/worldInit
COPY ./uploadBackupToS3.sh /bin/uploadBackupToS3

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
  unzip awscliv2.zip && \
  ./aws/install