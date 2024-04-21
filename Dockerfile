# etap 1
# użycie obrazu bazowego metodą od podstaw
FROM scratch AS build

# zadeklarownie zmiennej VERSION użwanej w procesie budowania
ARG VERSION
# użycie obrazu bazowego z minimalnym systemem plików linuksa alipine
ADD alpine-minirootfs-3.19.1-x86_64.tar /

# okreśelnie katalogu w którym będzie budownana aplikacja js
WORKDIR /usr/app

# aktualizacja pakietów, instalacja node i wyczyszczenia pamięci cache
RUN apk update && \
    apk add nodejs npm && \
    rm -rf /var/cache/apk/*

# przekopiowanie plików z używanymi bibliotekami js i ich instalacja
COPY ./package.json ./
RUN npm install

# skopiowanie plików aplikacji js do kontenera
COPY ./app.js ./

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

# skopiowanie plików z poprzedniego etapu do obrazu do obcego 
COPY --from=build /usr/app /usr/share/nginx/html
# skopiowanie pliku konfiguracyjengo nginx
COPY ./default.conf /etc/nginx/conf.d

WORKDIR /usr/share/nginx/html

# wystawienie portu 80, na którym domyślnie działa nginx
EXPOSE 80

# ustawienie komendy sprawdzającej czy aplikacja działa poprawnie
HEALTHCHECK --interval=20s --timeout=3s --start-period=5s --retries=2 \
    CMD curl -f http://localhost:80 || exit 1

# uruchomienia serwera nginx i aplikacji js wewnątrz kontenera
CMD nginx -g "daemon off;" & node app.js  
