FROM ubuntu:16.04

ENV HOME /root
ENV WEB_ROOT /var/www/sturents.com
# Define versions here
ENV XDEBUG_VERSION xdebug-2.4.0rc4.tgz

# Common env
ENV TERM xterm
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV DEBIAN_FRONTEND noninteractive

# Setup apt and install all
RUN \
    echo 'Installing apache2, php7 and dependencies' && \
    apt-get clean && apt-get update -y && \
    apt-get install -y locales && \
    locale-gen en_US.UTF-8 && \
    dpkg-reconfigure locales && \
    apt-get install -y --no-install-recommends apt-utils && \
    apt-get install -y wget curl python htop git vim locate zip unzip zsh python-software-properties software-properties-common build-essential libpcre3-dev nodejs npm && \
    apt-get install -y libtool autoconf uuid-dev pkg-config libsodium18 ghostscript && \
    add-apt-repository -y ppa:ondrej/php && \
    add-apt-repository -y ppa:ondrej/mysql-5.6 && \
    add-apt-repository -y ppa:brightbox/ruby-ng && \
    apt-get update && \
    apt-get dist-upgrade -y && \
    apt-get install -y apache2 \
        php7.0-cli php7.0-fpm php7.0-mysql php7.0-curl \
        php7.0-gd php7.0-gmp php7.0-mcrypt php7.0-intl \
        php7.0-dev php7.0-xsl php7.0-imap php7.0-ldap \
        php7.0-xml php7.0-bcmath php7.0-mbstring \
        php7.0-soap php-memcached php-pear php7.0-zip \
        xvfb libsqlite3-dev ruby2.2 ruby2.2-dev libxext6 xfonts-75dpi \
        fontconfig libxrender1 xfonts-base libssh2-1-dev libssh2-1 libapache2-mod-php7.0 \
        mysql-server-5.6 && \
    # Apache cleaup and dir perms
    echo 'Performing apache cleaup' && \
    mkdir -p /var/run/apache2 /var/lock/apache2 /var/log/apache2 && \
    rm -rf /var/www/html/* && \
    chown -R www-data /var/www/ && \
    chmod -R 755 /var/www/ && \
    sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride all/' /etc/apache2/apache2.conf && \
    touch /var/log/apache2/access.log && chown www-data /var/log/apache2/access.log && \
    touch /var/log/apache2/error.log && chown www-data /var/log/apache2/error.log && \

    # Install xdebug    
    echo 'Installing Xdebug' && \
    wget http://xdebug.org/files/$XDEBUG_VERSION -O xdebug.tgz && \
    tar xzf xdebug.tgz && \
    rm -f xdebug.tgz && \
    cd xdebug-*/ && \
    phpize && \
    ./configure --with-php-config=/usr/bin/php-config && \
    make && \
    export TEST_PHP_ARGS='-n' && \
    make test && \
    make install && \
    cd .. && \
    rm -Rf xdebug-*/ && \

    # Install zmq
    #apt-get install -y libtool autoconf uuid-dev pkg-config libsodium18 && \
    #wget https://archive.org/download/zeromq_4.1.4/zeromq-4.1.4.tar.gz && \
    #tar -xvzf zeromq-4.1.4.tar.gz && \
    #cd zeromq-4.1.4 && \
    #./configure && \
    #make && make install && \
    #ldconfig && \
    # zmq php binding
    #git clone git://github.com/mkoppanen/php-zmq.git && \
    #cd php-zmq && \
    #phpize && ./configure && \
    #make && make install && \
    # include zmq in php
    #echo 'extension=zmq.so' > /etc/php/7.0/mods-available/zmq.ini && \
    #phpenmod zmq && \

    # Install ruby dependencies    
    ruby -v && \
    gem install --no-ri --no-rdoc mailcatcher && \
    mailcatcher && \

    # install Composer
    curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer && \
    composer config -g github-oauth.github.com aeff6491f52163a011cba0b6b6286f5492e25ab6 && \

    # Npm + Bower + gulp    
    npm install -g bower && \
    npm install -g gulp && \
    ln -s /usr/bin/nodejs /usr/bin/node && \
    bower -version && \
    npm -v && node -v && bower -v && \
    chown -R www-data ~/.npm && \

    # WKHTMLTOPDF
    wget -qq http://download.gna.org/wkhtmltopdf/0.12/0.12.2.1/wkhtmltox-0.12.2.1_linux-trusty-amd64.deb && \
    dpkg -i wkhtmltox-0.12.2.1_linux-trusty-amd64.deb && \
    apt-get -f -y install && \
    apt-get -y install xvfb && \
    echo 'xvfb-run --server-args="-screen 0, 1024x768x24" /usr/local/bin/wkhtmltopdf $*' > /usr/bin/wkhtmltopdf.sh && \
    chmod a+rx /usr/bin/wkhtmltopdf.sh && \
    ln -s /usr/bin/wkhtmltopdf.sh /usr/bin/wkhtmltopdf && \
    wkhtmltopdf --version && \
    
    # Hoodiecrow
    git clone https://github.com/andris9/hoodiecrow && \ 
    npm install -g hoodiecrow-imap && \

    # Cleanup    
    apt-get clean && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    # Copy ssh keys for bitbucket access etc
    # TODO

    # Mysql
    service mysql start && \
    mysql -uroot -e 'create database sturents' && \
    mysql -uroot -e 'create database sturents_test'

    # Configure apache2 and enable sites
COPY resources/sturents-ssl.conf /etc/apache2/sites-available/
COPY resources/sturents-test.conf /etc/apache2/sites-available/ 
RUN \
    echo '127.0.0.1 local.sturents test.sturents static.sturents test-static.sturents' >> /etc/hosts && \
    echo 'ServerName local.sturents' >> /etc/apache2/apache2.conf && \  
    a2ensite sturents-ssl && \
    a2enmod headers && \
    service apache2 reload

EXPOSE 80
EXPOSE 443

WORKDIR $HOME

# Get source from bitbucket and build site
# TODO after ssh agent setup

# For now we copy source from host
COPY resources/source/ $HOME
RUN \
    cd $HOME/source && \
    npm install && npm rebuild node-sass && \
    composer install && \
    gulp bower && gulp build


