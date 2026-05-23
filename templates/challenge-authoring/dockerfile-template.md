# Dockerfile Template

Use this as a starting point for a reproducible challenge environment.

Adapt the base image, dependency installation, and test command to match the
selected repository.

```dockerfile
# syntax=docker/dockerfile:1

FROM <language-runtime-image>:<exact-version>

WORKDIR /workspace

# Install system dependencies during build.
# Keep this list minimal and pinned where practical.
RUN <install-system-dependencies>

# Copy repository files into the image.
COPY . /workspace

# Ensure the image is built from the expected immutable repository state.
# Replace this with a validation command appropriate for the environment.
ARG REPOSITORY_COMMIT
RUN test -n "$REPOSITORY_COMMIT"

# Install project dependencies during build, not during test runtime.
RUN <install-project-dependencies>

# Runtime should not require network access.
ENV CI=true

# Use the repository's test runner or the provided test.sh wrapper.
CMD ["bash", "test.sh"]
```

## Reproducibility Notes

- Use an exact immutable commit for the challenge base.
- Install dependencies during the image build.
- Avoid installing dependencies during test runtime.
- Keep runtime validation working without network access.
- Pin base images and dependency versions where practical.
- Keep the image small enough to build and run predictably.
- Avoid relying on host machine files, caches, credentials, or environment
  variables.
