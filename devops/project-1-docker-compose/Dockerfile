# syntax=docker/dockerfile:1.7
# Multi-stage Dockerfile для EconTrainer (static SPA + nginx).
# Stage 1 — подготовка статики (минификация);
# Stage 2 — лёгкий runtime на nginx-alpine.

FROM node:22-alpine AS build
WORKDIR /src

# Минимум build-инструментов: html-minifier + clean-css + terser
RUN npm i -g --no-fund --no-audit \
    html-minifier-terser@7 \
    clean-css-cli@5 \
    terser@5

COPY app/ ./app/

# Минификация HTML
RUN mkdir -p /out \
 && cd app && for f in *.html; do \
      html-minifier-terser --collapse-whitespace --remove-comments \
        --minify-css true --minify-js true \
        -o /out/$f $f; \
    done

# Минификация CSS
RUN mkdir -p /out/css \
 && cleancss --batch -O1 -o /out/css/styles.css app/css/styles.css

# Минификация JS — js/*.js + data/*.js
RUN mkdir -p /out/js /out/data \
 && cd app/js   && for f in *.js; do terser --compress --mangle -o /out/js/$f $f; done \
 && cd /src     && cd app/data && for f in *.js; do terser --compress --mangle -o /out/data/$f $f; done

# === Runtime ===
FROM nginx:1.27-alpine AS runtime
LABEL org.opencontainers.image.title="EconTrainer"
LABEL org.opencontainers.image.description="Адаптивный тренажёр по олимпиадам по экономике"
LABEL org.opencontainers.image.source="https://github.com/igorshunov/econ-olympiad-trainer"

# Конфиг nginx с cleanUrls (по аналогии с Vercel)
RUN rm /etc/nginx/conf.d/default.conf
COPY nginx/default.conf /etc/nginx/conf.d/default.conf

# Статика
COPY --from=build /out /usr/share/nginx/html

HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD wget -qO- http://127.0.0.1/healthz || exit 1

EXPOSE 80
