# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for license information.

ARG BASE_IMAGE=placeholder
FROM ${BASE_IMAGE}

USER root

ARG REMOTE_USER
ARG NEW_UID
ARG NEW_GID
SHELL ["/bin/sh", "-c"]

RUN set -eux; \
    if [ -z "${REMOTE_USER:-}" ]; then \
        echo "ERROR: REMOTE_USER is not set." >&2; \
        exit 1; \
    fi; \
    if ! echo "${NEW_UID:-}" | grep -Eq '^[0-9]+$'; then \
        echo "ERROR: NEW_UID must be a numeric UID." >&2; \
        exit 1; \
    fi; \
    if ! echo "${NEW_GID:-}" | grep -Eq '^[0-9]+$'; then \
        echo "ERROR: NEW_GID must be a numeric GID." >&2; \
        exit 1; \
    fi; \
    \
    if ! getent passwd "${REMOTE_USER}" >/dev/null 2>&1; then \
        echo "ERROR: Remote user '${REMOTE_USER}' was not found." >&2; \
        exit 1; \
    fi; \
    \
    OLD_UID="$(id -u "${REMOTE_USER}")"; \
    OLD_GID="$(id -g "${REMOTE_USER}")"; \
    HOME_FOLDER="$(getent passwd "${REMOTE_USER}" | cut -d: -f6)"; \
    \
    EXISTING_USER="$(getent passwd | awk -F: -v uid="${NEW_UID}" '$3 == uid {print $1; exit}')"; \
    EXISTING_GROUP="$(getent group | awk -F: -v gid="${NEW_GID}" '$3 == gid {print $1; exit}')"; \
    \
    if [ "${OLD_UID}" = "${NEW_UID}" ] && [ "${OLD_GID}" = "${NEW_GID}" ]; then \
        echo "UID and GID are already correct: ${NEW_UID}:${NEW_GID}."; \
    elif [ -n "${EXISTING_USER}" ] && [ "${OLD_UID}" != "${NEW_UID}" ]; then \
        echo "ERROR: UID ${NEW_UID} is already used by '${EXISTING_USER}'." >&2; \
        exit 1; \
    else \
        TARGET_GID="${NEW_GID}"; \
        \
        if [ "${OLD_GID}" != "${NEW_GID}" ] && [ -n "${EXISTING_GROUP}" ]; then \
            echo "GID ${NEW_GID} is already used by '${EXISTING_GROUP}'. Keeping existing GID ${OLD_GID}."; \
            TARGET_GID="${OLD_GID}"; \
        fi; \
        \
        if command -v groupmod >/dev/null 2>&1 && \
           [ "${OLD_GID}" != "${TARGET_GID}" ]; then \
            groupmod --gid "${TARGET_GID}" "${REMOTE_USER}"; \
        fi; \
        \
        if command -v usermod >/dev/null 2>&1; then \
            usermod --uid "${NEW_UID}" --gid "${TARGET_GID}" "${REMOTE_USER}"; \
        else \
            echo "ERROR: 'usermod' is required but was not found." >&2; \
            exit 1; \
        fi; \
        \
        if [ -d "${HOME_FOLDER}" ]; then \
            chown -R "${NEW_UID}:${TARGET_GID}" "${HOME_FOLDER}"; \
        fi; \
        \
        echo "Updated '${REMOTE_USER}' from ${OLD_UID}:${OLD_GID} to ${NEW_UID}:${TARGET_GID}."; \
    fi

ARG IMAGE_USER
USER ${IMAGE_USER}
