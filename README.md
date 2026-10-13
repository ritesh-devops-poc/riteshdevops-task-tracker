# Ritesh DevOps Task Tracker

A production-ready DevOps POC built around a Node.js task management application.

The purpose of this project is to implement and demonstrate a complete production-oriented DevOps lifecycle, including source control, CI/CD, containerization, infrastructure as code, Kubernetes, AWS, database management, scaling, security, monitoring, backup, and disaster recovery.

## Application Overview

Ritesh DevOps Task Tracker is a simple task management application.

### Application Functionality

- Create a task
- List existing tasks
- Mark a task as completed
- Delete a task

## Technology Stack

- Node.js
- Express.js
- EJS
- PostgreSQL
- HTML
- CSS
- npm

## Current Application Architecture

```text
Browser
   |
   v
Express.js
   |
   v
EJS
   |
   v
PostgreSQL
```

## Dev Deployment

The Dev environment deployment is automated using GitHub Actions and AWS Systems Manager (SSM).

The pipeline runs after a pull request is merged into the `develop` branch. It identifies the Dev EC2 instance using its `Environment=dev` and `Application=task-tracker` tags, deploys the merged commit through SSM, configures PostgreSQL, and manages the application using systemd.
