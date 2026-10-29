FROM ruby:4.0.0-slim
RUN apt-get update -qq && apt-get install -y --no-install-recommends build-essential && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY Gemfile Gemfile.lock ./
RUN bundle install
COPY . .
RUN mkdir -p log tmp/pids storage && chown -R 1000:1000 /app
USER 1000:1000
EXPOSE 3001
CMD ["bundle", "exec", "rails", "s", "-b", "0.0.0.0", "-p", "3001"]
