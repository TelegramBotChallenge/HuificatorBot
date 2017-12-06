FROM google/dart

RUN mkdir /app
WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN pub get

COPY . .

CMD ["dart", "lib/main.dart"]
