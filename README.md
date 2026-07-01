# CAREamics_Nextflow

This repository provides modules and an example pipeline for image restoration algorithms available through CAREamics. These modules allow training and predicting with deep learning models for the algorithms N2V, N2N and CARE.

## Modules

### Train N2V

- **Process name**: `CAREAMICS_TRAIN_N2V`
- **location**: [modules/careamics/train/n2v]()

### Train N2N

- **Process name**: `CAREAMICS_TRAIN_N2N`
- **location**: [modules/careamics/train/n2n]()

### Train CARE

- **Process name**: `CAREAMICS_TRAIN_CARE`
- **location**: [modules/careamics/train/care]()

### Predict

- **Process name**: `CAREAMICS_PREDICT`
- **location**: [modules/careamics/predict]()

## Pipeline

There is also an example pipeline which can be used to train and then perform inference with any of N2V, N2N and CARE algorithms.

### Run with example data

Training and validation, inputs and targets can each be either the path to a file or a directory, in which case all the valid files within that directory will be used for training.

Images to perform inference on are provided through a sample sheet which must have the column `data_path`. Each `data_path` value can be either a path to an image or a directory, a separate process will be created for each row of the sample sheet.

1. Clone the repo:

    ```console
    git clone git@github.com:CAREamics/CAREamics_nextflow.git
    chmod +x CAREamics_nextflow/bin/*
    ```

2. Download the example data using the provided script, we recommend using `uv` for this:

    This will also create a prediction sample sheet called `example_n2v_predict.csv`.

    ```console
    uv run get_example_data/n2v.py -wd .
    ```

    **Note:** `-wd` is the working directory.

3. Run the pipeline:

    ```console
    nextflow run careamics_pipeline.nf \
     -profile conda|singularity|docker,gpu|cpu \
     --train_data data/denoising-N2V_SEM.unzip/SEM/train.tif \
     --val_data data/denoising-N2V_SEM.unzip/SEM/validation.tif \
     --prediction_csv example_n2v_predict.csv \
     --outdir results \
     -params-file params_n2v.json \
    ```

**Tip**: To run locally you might want to use the flag `-c local.config` that will reduce the resource requirements of the label `process_medium`.