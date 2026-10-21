# TT-RSS with the Feedly theme

A thin extension of the maintained [`ghcr.io/tt-rss/tt-rss:latest`](https://github.com/tt-rss/tt-rss) image. Upstream currently uses **Alpine 3.24.2 and PHP 8.5** and publishes TT-RSS as rolling releases rather than numbered releases. The Feedly theme is included; Fever is no longer installed.

## Build and publish

The image repository is configured in `.envrc` and loaded by direnv, not hardcoded in the Makefile.

```sh
direnv allow                         # load IMAGE from .envrc
make build                           # registry.rocketeer.be/ttrss:latest
# Authenticate once if needed:
podman login registry.rocketeer.be
make push                            # builds, then pushes
```

Use `make push TAG=<version>` to publish a specific tag. `IMAGE` and `PODMAN` are also overridable. Pass extra build options with, for example, `make push BUILD_ARGS="--no-cache --build-arg FEEDLY_REF=<commit>"`.

The Kubernetes chart in `Rocketeer/server/charts/ttrss` uses `registry.rocketeer.be/ttrss:latest`. If publishing a versioned tag, set its `imageTag` when deploying.

## Run

```sh
cp .env.example .env
# Edit .env: set TTRSS_DB_PASS and the externally visible TTRSS_SELF_URL_PATH.
docker compose build --pull
docker compose up -d
```

Open <http://localhost:8280/tt-rss/> (or your configured URL). The default login is `admin`; if `ADMIN_USER_PASS` is unset, find the generated initial password with `docker compose logs app`. Select Feedly in TT-RSS preferences to use the theme.

Compose runs PostgreSQL, the app (PHP-FPM), the feed updater, and upstream nginx separately. The app and web services share the `app-data` volume; the database persists in `db-data`. Upstream initializes and migrates the schema on app startup. Only nginx is published to the host.

## Update

Back up the database first, then:

```sh
docker compose pull db web-nginx
docker compose build --pull --no-cache
docker compose up -d
```

`--pull` refreshes the upstream TT-RSS image; `--no-cache` also refreshes the theme. To pin a theme revision, build with `--build-arg FEEDLY_REF=<commit>`. For a fixed TT-RSS deployment, replace the Dockerfile's `latest` tag with an upstream `sha-*` tag or digest.

## Migrating from this repository's old image

This is **not a drop-in replacement for the old single-container image**.

- Back up your database and configuration before starting: schema upgrades may not be reversible.
- Current TT-RSS supports **PostgreSQL only**. MySQL deployments require a separate data migration before upgrading.
- Restore an existing PostgreSQL database into the new database service (or adapt Compose to point at your existing server). Do not attach an older PostgreSQL major version's data directory directly to PostgreSQL 17; use a dump/restore or a supported major-version upgrade.
- Use `TTRSS_DB_HOST`, `TTRSS_DB_PORT`, `TTRSS_DB_NAME`, `TTRSS_DB_USER`, `TTRSS_DB_PASS`, and `TTRSS_SELF_URL_PATH` instead of the old unprefixed variables. Docker `--link` settings and `DB_ENV_*` provisioning are no longer used.
- nginx now serves TT-RSS under `/tt-rss/` by default, not `/`. Update your public URL and reverse proxy accordingly.
- The app directory is now `/var/www/html/tt-rss`, managed by upstream in a shared volume. Do not reuse a volume mounted at the old `/var/www` path. Migrate any needed local assets deliberately; don't copy the old `config.php` over upstream's generated configuration.
- Remove Fever from your enabled plugins and do not migrate its plugin directory.

See upstream's [installation guide](https://tt-rss.org/docs/Installation-Guide.html) for additional configuration options.
