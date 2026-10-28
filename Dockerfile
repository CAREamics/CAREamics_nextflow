# NOTE: Currently build-container.yaml hard codes the the cuda version in the tag
#   DO NOT CHANGE CUDA VERSION WITHOUT CHANGING github workflow.
# PyTorch base image includes CUDA-enabled PyTorch
FROM pytorch/pytorch:2.7.1-cuda11.8-cudnn9-runtime
ARG CAREAMICS_VERSION
RUN pip install --no-cache-dir careamics==${CAREAMICS_VERSION}
