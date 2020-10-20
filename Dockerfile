FROM node:8

RUN mkdir /app

WORKDIR /app

COPY . /app

RUN rm -Rf ./node_modules

RUN npm install

RUN npm install elm

RUN chmod +x ./node_modules/elm/bin/elm

RUN ./node_modules/elm/bin/elm make example/Everything/Main.elm --output=./example/app.js

FROM nginx:1.15

COPY --from=0 /app/example/app.js /usr/share/nginx/html
COPY --from=0 /app/example/dat.gui.min.js /usr/share/nginx/html
COPY --from=0 /app/src/Gui/Gui.css /usr/share/nginx/html
COPY --from=0 /app/example/dat-gui-proxy.js /usr/share/nginx/html
COPY --from=0 /app/example/Everything/index.html /usr/share/nginx/html
COPY --from=0 /app/example/example.css /usr/share/nginx/html
RUN mkdir /usr/share/nginx/html/assets
COPY --from=0 /app/example/assets/ /usr/share/nginx/html/assets/

COPY ./nginx.conf /etc/nginx/conf.d/default.conf
