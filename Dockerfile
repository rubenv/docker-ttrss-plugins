# Upstream maintains Alpine, PHP, TT-RSS and its startup/schema migration scripts.
FROM ghcr.io/tt-rss/tt-rss:latest

# Apply to FPM only, after upstream's pool settings. Admin values cannot be
# overridden by application code or upstream's php.ini memory-limit rewrite.
RUN printf '[www]\nphp_admin_flag[session.upload_progress.enabled] = off\nphp_admin_value[memory_limit] = -1\n' \
    > "/etc/php${PHP_SUFFIX}/php-fpm.d/zz-security.conf"

# Keep this bundled plugin in plugins/ so upstream also syncs it into existing
# app volumes (plugins.local/ is deliberately preserved during upgrades).
RUN git clone --depth=1 --branch main \
    https://github.com/tt-rss/tt-rss-plugin-googlereaderkeys.git \
    "${SRC_DIR}/plugins/googlereaderkeys"

# Install into the source tree: upstream copies this into the shared app volume
# on startup (including upgrades). No Fever plugin is installed.
ARG FEEDLY_REF=master
RUN set -eux; \
    wget -O /tmp/feedly.tar.gz "https://codeload.github.com/levito/tt-rss-feedly-theme/tar.gz/${FEEDLY_REF}"; \
    mkdir -p /tmp/feedly; \
    tar xzf /tmp/feedly.tar.gz --strip-components=1 -C /tmp/feedly; \
    cp -R /tmp/feedly/feedly /tmp/feedly/feedly.css "${SRC_DIR}/themes/"; \
    # Feedly still uses the pre-4.0 Material Icons filenames. \
    sed -i 's|fonts/MaterialIcons-Regular\.|fonts/4.0.0/material-icons.|g' "${SRC_DIR}/themes/feedly.css"; \
    test -s "${SRC_DIR}/vendor/mervick/material-design-icons/fonts/4.0.0/material-icons.woff2"; \
    rm -rf /tmp/feedly /tmp/feedly.tar.gz
