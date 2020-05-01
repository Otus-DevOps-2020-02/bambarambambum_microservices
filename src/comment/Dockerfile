FROM alpine:3.9

ENV COMMENT_DATABASE_HOST comment_db
ENV COMMENT_DATABASE comments
ENV APP_HOME /app

RUN mkdir $APP_HOME
WORKDIR $APP_HOME

COPY Gemfile* $APP_HOME/
RUN apk --no-cache update && apk --no-cache --update add \
    ruby-full ruby-dev build-base ruby-bundler \
    && bundle install \
    && bundle clean --force

COPY . $APP_HOME

CMD ["puma"]
