FROM --platform=$BUILDPLATFORM python:3.10.7-slim-buster
ARG TARGETPLATFORM
ARG BUILDPLATFORM
RUN echo "I am running on $BUILDPLATFORM, building for $TARGETPLATFORM" > /log
RUN curl -fsSL https://tailscale.com/install.sh | sh


ENV PYTHONUNBUFFERED=true
ENV POETRY_HOME=/opt/poetry
ENV POETRY_VIRTUALENVS_IN_PROJECT=true
ENV PATH="$POETRY_HOME/bin:$PATH"
RUN python -c 'from urllib.request import urlopen; print(urlopen("https://install.python-poetry.org").read().decode())' | python -

# RUN curl -sSL https://install.python-poetry.org | python3 -
RUN echo $PATH
RUN ls /opt/
# RUN which poetry
# RUN poetry install


COPY . /mpyc

WORKDIR /mpyc

RUN poetry config virtualenvs.create false \
    && poetry install $(test "$YOUR_ENV" == production && echo "--no-dev") --no-interaction --no-ansi
