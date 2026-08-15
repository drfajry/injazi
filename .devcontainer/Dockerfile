FROM mcr.microsoft.com/devcontainers/base:ubuntu

RUN sudo apt-get update 
&& sudo apt-get install -y curl git unzip xz-utils zip libglu1-mesa 
&& sudo rm -rf /var/lib/apt/lists/*

RUN sudo git clone --depth 1 -b stable https://github.com/flutter/flutter.git /opt/flutter 
&& sudo chown -R vscode:vscode /opt/flutter

ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"

USER vscode

RUN flutter config --no-analytics 
&& flutter --version
