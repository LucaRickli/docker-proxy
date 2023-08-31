FROM alpine

RUN apk --update add socat
EXPOSE 80
CMD socat -d -d TCP-L:80,fork UNIX:/var/run/docker.sock
