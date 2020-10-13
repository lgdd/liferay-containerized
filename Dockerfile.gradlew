FROM azul/zulu-openjdk-alpine:11

ARG LIFERAY_UID

RUN addgroup -S liferay && adduser -S liferay -G liferay -u ${LIFERAY_UID:-100} && \
    apk --update --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/v3.10/main/ add \
    gcompat

USER liferay

WORKDIR /home/liferay

COPY --chown=liferay:liferay gradle gradle
COPY --chown=liferay:liferay gradlew .
COPY --chown=liferay:liferay gradle.properties .

RUN BUNDLE_URL=$(cat gradle.properties | grep liferay.workspace.bundle.url= | cut -d'=' -f2) && \
    mkdir -p .liferay/bundles && \
    wget -P .liferay/bundles "$BUNDLE_URL" && \
    ./gradlew

ARG TARGET_ENV=prod

COPY --chown=liferay:liferay docker-entrypoint.sh .
COPY --chown=liferay:liferay settings.gradle .
COPY --chown=liferay:liferay build.gradle .
COPY --chown=liferay:liferay configs/common configs/common
COPY --chown=liferay:liferay configs/$TARGET_ENV configs/$TARGET_ENV
COPY --chown=liferay:liferay themes themes
COPY --chown=liferay:liferay modules modules

ENTRYPOINT ["./gradlew"]
CMD ["-t","deploy"]