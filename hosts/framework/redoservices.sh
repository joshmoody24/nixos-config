#!/bin/bash
# Caddy runs via systemd - see services.caddy in configuration.nix

exec distrobox enter redo -- bazelisk run services \
    redo-cockroachdb \
    redo-valkey \
    temporal-server \
    temporal-worker \
    redo-notice-server \
    redo-api-server \
    redo-merchant-server \
    redo-shopify-server \
    redo-public-server \
    redo-admin-server \
    redo-customer-portal-server \
    redo-merchant-app-vite \
    redo-admin-app-vite \
    redo-return-app-vite \
    redo-storefront \
    redo-shopify-extension
