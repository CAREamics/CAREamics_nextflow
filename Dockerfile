ARG CAREAMICS_VERSION

# cpu build, instally cpu pytorch first
FROM python:3.11-slim AS cpu
ARG CAREAMICS_VERSION
RUN pip install --no-cache-dir torch torchvision --index-url https://download.pytorch.org/whl/cpu
RUN pip install --no-cache-dir careamics==${CAREAMICS_VERSION}

# gpu build, pytorch base image already includes pytorch
FROM pytorch/pytorch:2.5.1-cuda11.8-cudnn9-runtime AS gpu
ARG CAREAMICS_VERSION
RUN pip install --no-cache-dir careamics==${CAREAMICS_VERSION}