# Developer Guide

This guide explains how to set up, run, and test the project using Docker for both development and production simulation.

## Prerequisites

*   Docker ([Installation Guide](https://docs.docker.com/engine/install/))
*   Docker Compose ([Installation Guide](https://docs.docker.com/compose/install/)) - Usually included with Docker Desktop.

## Setup

1.  **(Assumed)** Clone the repository to your local machine.
2.  **Create Development Environment File (`.env`):**
    *   The development container loads configuration from a `.env` file in the project root.
    *   Copy the template file: `cp .env.example .env`
    *   Edit the `.env` file and provide values for the required variables:
        *   `HMAC_SECRET`: Should be a 32-byte hexadecimal string (64 characters). You can generate one using:
            ```bash
            openssl rand -hex 32
            ```
        *   `SECRET_KEY_BASE`: Should be at least 64 bytes long. You can generate one using the Mix task (either locally if Elixir is installed, or via the dev container later):
            ```bash
            mix phx.gen.secret 64
            ```
    *   Paste the generated values into your `.env` file.

## Development Environment (Docker)

This environment uses `Dockerfile.dev` and `docker-compose.yml`. It provides live code reloading for faster development.

1.  **Build/Rebuild Development Image:**
    *(Ensure Docker Desktop or Docker Engine is running)*
    ```bash
    docker compose build api_dev
    ```
    *(Replace `api_dev` if your service name in `docker-compose.yml` is different)*

2.  **Start Container Service:**
    *(This starts the container in the background but doesn't run `mix phx.server`)*
    ```bash
    docker compose up -d api_dev
    ```

3.  **Access Container Shell (Recommended for most tasks):**
    Open one or more terminals and run the following to get an interactive shell inside the running container:
    ```bash
    docker compose exec api_dev /bin/bash
    ```
    Inside this shell, you can run standard Mix commands:
    *   Start the Phoenix server: `mix phx.server`
    *   Run tests: `MIX_ENV=test mix test`
    *   Start an IEx console: `iex -S mix`
    *   Generate secrets (if needed): `mix phx.gen.secret 64`
    *   Run any other Mix tasks (`mix ecto.migrate`, etc.)
    *   Type `exit` to leave the shell.

4.  **Run One-Off Commands (Alternative):**
    You can execute commands directly without entering the shell using `docker compose run`. This creates a *new temporary container* based on the service definition.
    ```bash
    # Example: Run tests directly (ensures correct env)
    docker compose run --rm api_dev env MIX_ENV=test mix test

    # Example: Generate a secret
    docker compose run --rm api_dev mix phx.gen.secret 64
    ```
    *Note: `--rm` automatically removes the temporary container after the command exits.*

5.  **Stop Container Service:**
    ```bash
    docker compose down
    ```
    *Use `docker compose down -v` to also remove associated volumes (like `deps`, `_build`) if you want a cleaner stop.*

---

## Testing the Production Build Locally

This section describes how to build and run the minimal OTP release image created by `Dockerfile`. It simulates how the production container would run, requiring runtime configuration via environment variables.

**IMPORTANT:** This is for **local testing only**. Actual production deployments should inject environment variables securely using platform-specific methods (e.g., Kubernetes Secrets, PaaS config vars), **not** using local `.env.*` files.

1.  **Build Production Image:**
    *(Ensure Docker Desktop or Docker Engine is running)*
    ```bash
    # Replace 'your-project-name-prod' with your desired image tag
    docker build -f Dockerfile -t your-project-name-prod:latest .
    ```

2.  **Create Local Production Environment File (Optional but Recommended):**
    To easily provide environment variables for local testing, create a file named `.env.prod.local` (or similar). **Ensure this filename is added to your `.gitignore` file!**

    Edit `.env.prod.local` with values suitable for testing the production image (use strong, *non-production* secrets):
    ```dotenv
    # .env.prod.local (For Local Prod Image Testing Only - MUST BE IN .gitignore)

    MIX_ENV=prod
    PORT=4000 # The port the app listens on *inside* the container
    PHX_HOST=your-app.com # Required by runtime.exs for URL generation (use a placeholder)
    # DATABASE_URL=ecto://user:pass@prod-db-host:5432/prod_db # Example for prod DB
    SECRET_KEY_BASE="PASTE_A_STRONG_64_BYTE_SECRET_HERE" # Use a *different* one than dev/test
    HMAC_SECRET="PASTE_A_STRONG_32_BYTE_HEX_SECRET_HERE" # Use a *different* one than dev/test
    # Add any other required production ENV VARS here (e.g., MAILER config)
    ```
    *(Generate strong, unique secrets for `SECRET_KEY_BASE` and `HMAC_SECRET` specifically for this local test.)*

3.  **Run Production Container using Local Env File:**
    Use the `--env-file` flag to load variables from your local test file and `-p` to map the host port to the container port.

    *   **Option A: Run Attached (Foreground - see logs immediately):**
        ```bash
        docker run -it --rm \
          -p 4000:4000 \
          --env-file .env.prod.local \
          --name your-project-prod-test \
          your-project-name-prod:latest
        ```
        *(Press `Ctrl+C` to stop)*

    *   **Option B: Run Detached (Background):**
        ```bash
        docker run -d --rm \
          -p 4000:4000 \
          --env-file .env.prod.local \
          --name your-project-prod-test \
          your-project-name-prod:latest
        ```

4.  **Verify and Test:**
    *   If running attached (`-it`), check the logs directly in the terminal for startup messages (e.g., `[info] Running YourAppWeb.Endpoint with Bandit...`).
    *   If running detached (`-d`), check logs using: `docker logs your-project-prod-test`
    *   Test application endpoints from your host machine (e.g., `curl http://localhost:4000/api/v1/sign ...`).

5.  **Stop Detached Container:**
    *(Only needed if you used Option B: `docker run -d`)*
    ```bash
    docker stop your-project-prod-test
    ```
    *(The `--rm` flag ensures the container is removed once stopped)*

---

## Configuration Notes

*   **`HMAC_SECRET`**: Critical for specific application logic (e.g., `/sign`, `/verify` endpoints). Must be provided as an environment variable (hexadecimal format).
*   **`SECRET_KEY_BASE`**: Required by Phoenix for session signing, CSRF protection, etc. Must be >= 64 bytes and provided as an environment variable.
*   **Loading Source Summary:**
    *   **Development (`mix phx.server` via `docker compose exec`):** Reads variables defined in `.env` (loaded by Docker Compose). Runtime configuration handled by `config/runtime.exs`.
    *   **Testing (`mix test`):** Uses hardcoded secrets and configuration defined in `config/test.exs`. Environment variables are generally ignored unless explicitly read by test setup.
    *   **Production (Release via `Dockerfile`):** Reads variables **only** from the OS environment provided to the `docker run` command (or injected by the deployment platform like Kubernetes, Heroku, Fly.io, etc.). Runtime configuration handled by `config/runtime.exs`. The `.env.prod.local` file mentioned above is **strictly for local testing convenience** and is **not** used in actual deployments.