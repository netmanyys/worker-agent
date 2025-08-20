# targets/Dockerfile
FROM alpine:3.20

ARG USERNAME=ubuntu
ARG UID=1000
ARG GID=1000

RUN set -eux; \
  apk add --no-cache openssh-server openssh-sftp-server python3 sudo; \
  \
  # user + group
  addgroup -g "${GID}" "${USERNAME}"; \
  adduser  -D -u "${UID}" -G "${USERNAME}" "${USERNAME}"; \
  \
  # unlock account so sshd will allow pubkey logins
  passwd -u "${USERNAME}"; \
  \
  # passwordless sudo (permanent, correct perms so sudo reads it)
  printf "%s ALL=(ALL) NOPASSWD:ALL\n" "${USERNAME}" > /etc/sudoers.d/99-${USERNAME}-nopw; \
  chown root:root /etc/sudoers.d/99-${USERNAME}-nopw; \
  chmod 0440 /etc/sudoers.d/99-${USERNAME}-nopw; \
  grep -q '^#includedir /etc/sudoers.d' /etc/sudoers || echo '#includedir /etc/sudoers.d' >> /etc/sudoers; \
  visudo -cf /etc/sudoers; \
  \
  # sshd: key-only, root pwd-disabled, ensure pubkey auth on
  sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config; \
  sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config; \
  sed -i 's/^#\?PubkeyAuthentication .*/PubkeyAuthentication yes/' /etc/ssh/sshd_config; \
  sed -i 's@^#\?AuthorizedKeysFile .*@AuthorizedKeysFile .ssh/authorized_keys@' /etc/ssh/sshd_config; \
  \
  # home + ssh dir with sane perms (StrictModes compliant)
  mkdir -p /home/${USERNAME}/.ssh /var/run/sshd; \
  chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}; \
  chmod 0755 /home/${USERNAME}; \
  chmod 0700 /home/${USERNAME}/.ssh; \
  \
  # host keys
  ssh-keygen -A

EXPOSE 22
CMD ["/usr/sbin/sshd","-D","-e"]
