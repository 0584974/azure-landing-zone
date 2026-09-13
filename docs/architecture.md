# Architecture

This repository implements an Azure Landing Zone baseline aligned to management groups, subscription placement, centralized policy, and centralized observability.

## Sprint 2 design additions

- environment compilation layer (`scripts/compile-env.sh`)
- stage-based deployment scripts
- parameterized governance module for management-group policy assignment
- compiled compatibility output for the legacy `variables.json` model

## Current scope

- ALZ management-group hierarchy support
- management-group subscription placement
- management-group diagnostic settings
- baseline governance policy assignment

## Deferred to later sprints

- full connectivity deployment pipeline
- end-to-end platform bootstrap
- richer policy initiatives and exemptions workflow
- integration tests against Azure test tenants
