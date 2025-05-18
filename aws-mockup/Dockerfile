FROM elixir:1.17-alpine

# Install build tools and hex/rebar
RUN apk add --no-cache build-base git \
    && mix local.hex --force \
    && mix local.rebar --force

# Set working directory
WORKDIR /app

# Copy mix.exs and mix.lock first (for caching deps)
COPY mix.exs mix.lock ./

# Fetch dependencies
RUN mix deps.get

# Copy the rest of the source code
COPY . .

# Compile the project
RUN mix compile

# Expose the port your server runs on (change if needed)
EXPOSE 4000

# Run the server
CMD ["mix", "run", "--no-halt"]