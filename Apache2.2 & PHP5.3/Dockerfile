FROM debian:squeeze

LABEL maintainer="arditya@kekasi.co.id"

# squeeze new mirrors
RUN echo "deb http://archive.debian.org/debian/ squeeze contrib main non-free" > /etc/apt/sources.list

RUN apt-get update
# Common packages
RUN apt-get install -y --force-yes curl wget nano

RUN apt-get install -y --force-yes apache2 libapache2-mod-php5 ntp php5 php5-curl php5-gd php5-ldap php5-mcrypt php5-mysql vim

RUN a2enmod php5 rewrite ssl

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV LC_ALL en_US.UTF-8


ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR  /var/log/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid

RUN chown -R www-data:www-data /var/www

EXPOSE 80
EXPOSE 443 

#CMD ["/usr/sbin/apachectl", "-D", "FOREGROUND"]
ENTRYPOINT /etc/init.d/apache2 restart && bash