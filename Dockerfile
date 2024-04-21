# etap 1
# użycie obrazu bazowego metodą od podstaw
FROM scratch AS build

# zadeklarownie zmiennej VERSION użwanej w procesie budowania
ARG VERSION
# użycie obrazu bazowego z minimalnym systemem plików linuksa alipine
ADD alpine-minirootfs-3.19.1-x86_64.tar /

# aktualizacja pakietów, instalacja node, gita i  i wyczyszczenia pamięci cache
# pobranie klienta openssh który posłuży do uwierzytelnienia przy pobieraniu z repozytorium git
RUN apk update && \
    apk add nodejs npm && \
    apk add git && \
    apk add openssh-client && \
    rm -rf /var/cache/apk/*

# utworzenie katalogu .ssh w katalogu domowym użytkownika root
# nadanie uprawnień dla tego katalogu, w tym katalogu będą przechowywane klucze ssh
RUN mkdir -p /root/.ssh && \
    chmod 700 /root/.ssh

# dodanie klucza publicznego githuba do pliku known_hosts
RUN ssh-keyscan github.com >> ~/.ssh/known_hosts && eval $(ssh-agent)

# okreśelnie katalogu w którym będzie budownana aplikacja js
WORKDIR /usr/app
RUN --mount=type=ssh git clone git@github.com:adrianix2000/PAwChOspr1.git

WORKDIR /usr/app/PAwChOspr1
# przekopiowanie plików z używanymi bibliotekami js i ich instalacja
RUN npm install

# etap 2
# kolejny etap budowy obrazu
# wykorzsyatnie obrazu aplipne z nginx
# apline posiada manager pakietów który pozwoli na instalcje node, zwykły nginx nie posiada managera pakietów
FROM nginx:alpine
# przechwyucenie zmiennej środowiskowej zdeklarowanej w poprzednim etapie budowy i zapisanie jej w zmiennej środowiskowej
ARG VERSION
ENV APP_VERSION=${VERSION:-v1}

# aktualizacja/instalcja node/czyszczenia cache.
RUN apk update && \
    apk add nodejs npm && \
    rm -rf /var/cache/apk/*

WORKDIR /usr/share/nginx/html

# skopiowanie plików z poprzedniego etapu do obrazu do obcego 
COPY --from=build /usr/app/PAwChOspr1  /usr/share/nginx/html

# skopiowanie pliku konfiguracyjengo nginx
# RUN mv /usr/share/nginx/html/PAwChOspr1/default.conf /etc/nginx/conf.d
copy --from=build /usr/app/PAwChOspr1/default.conf /etc/nginx/conf.d

# wystawienie portu 80, na którym domyślnie działa nginx
EXPOSE 80

# ustawienie komendy sprawdzającej czy aplikacja działa poprawnie
HEALTHCHECK --interval=20s --timeout=3s --start-period=5s --retries=2 \
    CMD curl -f http://localhost:80 || exit 1

# uruchomienia serwera nginx i aplikacji js wewnątrz kontenera
CMD nginx -g "daemon off;" & node app.js  
