# Denoising_careamics

## setting up

```bash
git clone "this repo"
chmod +x Denoising_careamics/bin/*
```
## usage

- can be run on HPC slurm (if needed I will add the nextflow.config on the cluster)/locally
- using docker or apptainer
- predict.nf can be used independently from train.nf
  
## current usage

```bash
# locally on WSL/linux/Mac
nextflow run denoising_pipeline.nf -profile conda|singularity|docker -params-file params_n2v.json|params_n2n_care.json
# Tier1, UGent
nextflow run denoising_pipeline.nf -profile vsc_ugent,singularity -params-file params_n2v.json -w $VSC_SCRATCH_PROJECTS_BASE/project_number/path/work --singularity_cache_dir $VSC_SCRATCH_PROJECTS_BASE/project_number/path/.apptainer/ --tier1_project 2024_300
```

### How to get the container from seqera
```bash
wget https://wave.seqera.io/view/builds/bd-5130b64e7194c8c6_1
# use /tmp instead of $VSC_SCRATCH on Tier1
export APPTAINER_CACHE=$VSC_SCRATCH/.apptainer
export APPTAINER_TMP=$VSC_SCRATCH/.apptainer
apptainer pull careamics_wave.sif oras://community.wave.seqera.io/library/careamics:0.0.21--5130b64e7194c8c6
```
### How to run test

```bash
# for train n2v
nf-test test --profile conda modules/careamics/train/n2v/tests/main.nf.test
# for predict
nf-test test --profile conda modules/careamicspredict/tests/main.nf.test
# for all ?
nf-test test
```

