FROM centos:7.3.1611
MAINTAINER Antonella G <ncargcia@ilg.cat>

#Con yum update vamos a realizar las actualizaciones disponibles para los paquetes instalados
#Vamos a instalar tambien el repositorio epel, son paquetes adicionales y compatibles.
#Instalamos yum-utiles para tener disponible la herramientra yum-config-manager
#Inofy, para automatizar el reinicio del proceso despues de hacer cambios en el archivo de configuracion
#yum clean all, limpia los archivos de encabezados y paquetes.

RUN \
  yum update -y && \
  yum install -y epel-release && \
  yum install -y iproute python-setuptools hostname inotify-tools yum-utils which jq && \
  yum clean all && \

#instalamos supervisor que nos permite iniciar varios programas en un solo contenedor
  easy_install supervisor

#Update, para aactualizar el sistema
#instalamos el compresir de datos bzip

RUN \ 
yum update -y && \ 
yum install -y wget patch tar bzip2 unzip openssh-clients MariaDB-client

#Instalamos SSH

RUN \
  yum install -y openssh-server pwgen sudo vim mc links

#Se generan claves de identificacion

RUN ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N '' \
&& ssh-keygen -t dsa  -f /etc/ssh/ssh_host_dsa_key -N '' \
&& ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -N '' \
&& chmod 600 /etc/ssh/*

RUN \
  sed -i -r 's/.?UseDNS\syes/UseDNS no/' /etc/ssh/sshd_config && \
  sed -i -r 's/.?PasswordAuthentication.+/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
  sed -i -r 's/.?ChallengeResponseAuthentication.+/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config && \
  sed -i -r 's/.?PermitRootLogin.+/PermitRootLogin no/' /etc/ssh/sshd_config

RUN \
  sed -ri 's/^HostKey\ \/etc\/ssh\/ssh_host_ed25519_key/#HostKey\ \/etc\/ssh\/ssh_host_ed25519_key/g' /etc/ssh/sshd_config && \
  sed -ri 's/^#HostKey\ \/etc\/ssh\/ssh_host_dsa_key/HostKey\ \/etc\/ssh\/ssh_host_dsa_key/g' /etc/ssh/sshd_config && \
  sed -ri 's/^#HostKey\ \/etc\/ssh\/ssh_host_rsa_key/HostKey\ \/etc\/ssh\/ssh_host_rsa_key/g' /etc/ssh/sshd_config && \
  sed -ri 's/^#HostKey\ \/etc\/ssh\/ssh_host_ecdsa_key/HostKey\ \/etc\/ssh\/ssh_host_ecdsa_key/g' /etc/ssh/sshd_config && \
  sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config

#si el indicador se establece en no, ssh agregara automaticamente las nuevas claves de host a los archivos host conocidos.

RUN \
  echo -e "StrictHostKeyChecking no" >> /etc/ssh/ssh_config

#Sudoers anula la ruta al usar el comando 'sudo'

RUN \
  sed -i '/secure_path/d' /etc/sudoers

RUN \
  echo > /etc/sysconfig/i18n

RUN echo 'alias ls="ls --color"' >> ~/.bashrc \
&& echo 'alias ll="ls -lh"' >> ~/.bashrc \
&& echo 'alias la="ls -lha"' >> ~/.bashrc

#limpiamos la cahce para reducir el tamañado de la imagen de docker

RUN \
  yum clean all && rm -rf /tmp/yum*

ENV USER=www
ENV PASSWORD=iaw

# - Add supervisord conf, bootstrap.sh files
ADD container-files /

RUN \
   sed -ri "s/www/${USER}/g" /etc/supervisord.conf && \
   sed -ri "s/iaw/${PASSWORD}/g" /etc/supervisord.conf

VOLUME ["/data"]

#Le indicamos al contenedor los puertos en los deberia escuchar
EXPOSE 22 9001

#con entrypoint configuramos el contenedor que se ejecutara como ejecutable directamente

ENTRYPOINT ["/config/bootstrap.sh"]
