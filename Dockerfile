FROM alpine

RUN apk --update add socat
EXPOSE 8000
CMD socat -d -d TCP-L:8000,fork UNIX:/var/run/docker.sock
