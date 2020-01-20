FROM jenkins/jnlp-slave:3.19-1
MAINTAINER Rick <linuxsuren@gmail.com>

ENV HUGO_VERSION 0.54.0
ENV HUGO_ARCH Linux-64bit

RUN pwd

USER ${user}

# Install HUGO
RUN wget https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_${HUGO_ARCH}.tar.gz
RUN tar xzf hugo_${HUGO_VERSION}_${HUGO_ARCH}.tar.gz
RUN rm -r hugo_${HUGO_VERSION}_${HUGO_ARCH}.tar.gz 
RUN ls -hal 
RUN mv hugo /usr/bin/hugo 

ENTRYPOINT ["/usr/local/bin/jenkins-slave"]
