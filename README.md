# CAREamics Nextflow

Nextflow modules and subworkflows for training and running prediction with
[CAREamics](https://careamics.github.io). Compatible with installation using `nf-core` tooling.

The main entry points are the train-and-predict subworkflows for N2V, N2N, CARE,
and a generic CAREamics workflow that accepts an existing CAREamics configuration
file. If you already have a trained CAREamics checkpoint, use the prediction
module directly.

## Install with nf-core

Install components into your own Nextflow pipeline with `nf-core modules` or
`nf-core subworkflows` and the repository as a custom remote.

To install a subworkflow:

```console
nf-core subworkflows \
  -g https://github.com/CAREamics/CAREamics_nextflow.git \
  -b main \
  install image_train_predict_n2v_careamics
```

To install a module:

```console
nf-core modules \
  -g https://github.com/CAREamics/CAREamics_nextflow.git \
  -b main \
  install careamics/predict
```

> [!IMPORTANT]
> These modules use helper scripts stored in module `resources`, so the pipeline that imports them must enable module binaries:
>
>```nextflow
>nextflow.enable.moduleBinaries = true
>```
>
> CAREamics will work on integrating the scripts into a CLI for future versions so that this will no longer be necessary.


## What's included

| Type | Component | Use-case |
| --- | --- | --- |
| Subworkflow | [`image_train_predict_n2v_careamics`](#image_train_predict_n2v_careamics) | Easy N2V training and prediction. |
| Subworkflow | [`image_train_predict_n2n_careamics`](#image_train_predict_n2n_careamics) | Easy N2N training and prediction. |
| Subworkflow | [`image_train_predict_care_careamics`](#image_train_predict_care_careamics) | Easy CARE training and prediction. |
| Subworkflow | [`image_train_predict_careamics`](#image_train_predict_careamics) | Provide a CAREamics configuration file to have access to more advanced features for training and prediction. |
| Module | [`careamics/predict`](#careamicspredict) | Prediction with a pre-trained CAREamics checkpoint. |

Lower-level config and training modules are also available for custom workflows:
`careamics/config/n2v`, `careamics/config/n2n`, `careamics/config/care`, and
`careamics/train`.

## Subworkflows

All subworkflows emit `versions`, a channel containing `versions.yml` files from
the processes they run. CAREamics processes use the `process_medium` label.


### `image_train_predict_n2v_careamics`

Use this subworkflow to train and run prediction with Noise2Void (N2V); simple configuration parameters are exposed through the subworkflow's configuration channel, `ch_config`.

Process components:

- `careamics/config/n2v`
- `image_train_predict_careamics`

Labels: all component processes use `process_medium`.

Inputs:

| Channel | Structure | Notes |
| --- | --- | --- |
| `ch_config` | `[ val(meta), val(experiment_name), val(data_type), val(axes), val(patch_size), val(batch_size) ]` | `patch_size` is a space-separated spatial size, for example `"64 64"`. |
| `ch_train_data` | `[ val(meta), path(train_data), path(val_data) ]` | `train_data` is required. `val_data` is optional; use `[]` when absent. Can be a file or directory. |
| `ch_predict` | `[ val(meta), path(data) ]` | Data to predict on. Can be a file or directory. |

> [!NOTE]
> Additional N2V configuration options can be passed to the `CAREAMICS_CONFIG_N2V`
> process with `task.ext.args`, including `--num_epochs`, `--num_steps`,
> `--augmentations`, `--n_val_patches`, `--use_n2v2`, and `--n_channels`.

Outputs:

| Name | Structure | Pattern |
| --- | --- | --- |
| `careamics_config` | `[ val(meta), path(careamics_config) ]` | `careamics.yaml` |
| `model` | `[ val(meta), path(model) ]` | `checkpoints/*/*last.ckpt` |
| `predictions` | `[ val(meta), path(predictions) ]` | `predictions/*` |
| `versions` | `[ path(versions.yml) ]` | `versions.yml` |

### `image_train_predict_n2n_careamics`

Use this subworkflow to train and run prediction with Noise2Noise (N2N); simple configuration parameters are exposed through the subworkflow's configuration channel, `ch_config`.

Process components:

- `careamics/config/n2n`
- `image_train_predict_careamics`

Labels: all component processes use `process_medium`.

Inputs:

| Channel | Structure | Notes |
| --- | --- | --- |
| `ch_config` | `[ val(meta), val(experiment_name), val(data_type), val(axes), val(patch_size), val(batch_size) ]` | Shared simple CAREamics configuration fields. |
| `ch_train_data` | `[ val(meta), path(train_data), path(train_target), path(val_data), path(val_target) ]` | `train_data` and `train_target` are required. Validation data and targets are optional, but provide both together or use `[]` for both. Can be a file or a directory. |
| `ch_predict` | `[ val(meta), path(data) ]` | Data to predict on. Can be a file or a directory. |

> [!NOTE]
> Additional N2N configuration options can be passed to the `CAREAMICS_CONFIG_N2N`
> process with `task.ext.args`, including `--num_epochs`, `--num_steps`,
> `--augmentations`, `--n_val_patches`, `--n_channels_in`, and
> `--n_channels_out`.

Outputs:

| Name | Structure | Pattern |
| --- | --- | --- |
| `careamics_config` | `[ val(meta), path(careamics_config) ]` | `careamics.yaml` |
| `model` | `[ val(meta), path(model) ]` | `checkpoints/*/*last.ckpt` |
| `predictions` | `[ val(meta), path(predictions) ]` | `predictions/*` |
| `versions` | `[ path(versions.yml) ]` | `versions.yml` |

### `image_train_predict_care_careamics`

Use this subworkflow to train and run prediction with CARE; simple configuration parameters are exposed through the subworkflow's configuration channel, `ch_config`.

Process components:

- `careamics/config/care`
- `image_train_predict_careamics`

Labels: all component processes use `process_medium`.

Inputs:

| Channel | Structure | Notes |
| --- | --- | --- |
| `ch_config` | `[ val(meta), val(experiment_name), val(data_type), val(axes), val(patch_size), val(batch_size) ]` | Shared simple CAREamics configuration fields. |
| `ch_train_data` | `[ val(meta), path(train_data), path(train_target), path(val_data), path(val_target) ]` | `train_data` and `train_target` are required. Validation data and targets are optional, but provide both together or use `[]` for both. Can be a file or directory. |
| `ch_predict` | `[ val(meta), path(data) ]` | Data to predict on. Can be a file or directory. |

> [!NOTE]
> Additional CARE configuration options can be passed to the `CAREAMICS_CONFIG_CARE`
> process with `task.ext.args`, including `--num_epochs`, `--num_steps`,
> `--augmentations`, `--n_val_patches`, `--n_channels_in`, and
> `--n_channels_out`.

Outputs:

| Name | Structure | Pattern |
| --- | --- | --- |
| `careamics_config` | `[ val(meta), path(careamics_config) ]` | `careamics.yaml` |
| `model` | `[ val(meta), path(model) ]` | `checkpoints/*/*last.ckpt` |
| `predictions` | `[ val(meta), path(predictions) ]` | `predictions/*` |
| `versions` | `[ path(versions.yml) ]` | `versions.yml` |

### `image_train_predict_careamics`

Use this subworkflow when you already have a CAREamics configuration file,
typically created with the CAREamics Python library. This path gives access to
advanced CAREamics features that need more complex configuration than the simple
N2V, N2N, and CARE helper subworkflows expose.

Process components:

- `careamics/train`
- `careamics/predict`

Labels: all component processes use `process_medium`.

Inputs:

| Channel | Structure | Notes |
| --- | --- | --- |
| `ch_train` | `[ val(meta), path(careamics_config), path(train_data), path(train_target), path(val_data), path(val_target) ]` | `train_data` is required. `val_data` is optional. `train_target` and `val_target` are only needed for supervised algorithms. Use `[]` for missing optional paths. |
| `ch_predict` | `[ val(meta), path(data) ]` | Data to predict on. |

Outputs:

| Name | Structure | Pattern |
| --- | --- | --- |
| `model` | `[ val(meta), path(model) ]` | `checkpoints/*/*last.ckpt` |
| `predictions` | `[ val(meta), path(predictions) ]` | `predictions/*` |
| `versions` | `[ path(versions.yml) ]` | `versions.yml` |

## Modules

### `careamics/predict`

Use this module directly when you already have a pretrained CAREamics model and
want to add prediction to a pipeline.

- Process name: `CAREAMICS_PREDICT`
- Label: `process_medium`
- Input: `[ val(meta), path(data), path(model) ]`
- Output `predictions`: `[ val(meta), path("predictions/*") ]`
- Output `versions`: `versions.yml`

`data` can be a TIFF file or a directory containing TIFF files. `model` is a
trained `.ckpt` checkpoint. Additional CAREamics prediction options can be passed
through `task.ext.args`.

> [!NOTE]
> Additional prediction options can be passed to the `CAREAMICS_PREDICT` process
> with `task.ext.args`, including `--batch_size`, `--tile_size`,
> `--tile_overlap`, `--axes`, `--data_type`, and `--write_type`.

### Other modules

These modules are mainly used by the subworkflows, but can be installed and used
directly when needed.

| Module | Process | Label | Input | Output | Notes |
| --- | --- | --- | --- | --- | --- |
| `careamics/config/n2v` | `CAREAMICS_CONFIG_N2V` | `process_medium` | `[ val(meta), val(experiment_name), val(data_type), val(axes), val(patch_size), val(batch_size) ]` | `careamics_config`: `[ val(meta), path("careamics.yaml") ]`; `versions`: `versions.yml` | Creates a Noise2Void configuration. `task.ext.args` may include `--num_epochs`, `--num_steps`, `--augmentations`, `--n_val_patches`, `--use_n2v2`, and `--n_channels`. |
| `careamics/config/n2n` | `CAREAMICS_CONFIG_N2N` | `process_medium` | `[ val(meta), val(experiment_name), val(data_type), val(axes), val(patch_size), val(batch_size) ]` | `careamics_config`: `[ val(meta), path("careamics.yaml") ]`; `versions`: `versions.yml` | Creates a Noise2Noise configuration. `task.ext.args` may include `--num_epochs`, `--num_steps`, `--augmentations`, `--n_val_patches`, `--n_channels_in`, and `--n_channels_out`. |
| `careamics/config/care` | `CAREAMICS_CONFIG_CARE` | `process_medium` | `[ val(meta), val(experiment_name), val(data_type), val(axes), val(patch_size), val(batch_size) ]` | `careamics_config`: `[ val(meta), path("careamics.yaml") ]`; `versions`: `versions.yml` | Creates a CARE configuration. `task.ext.args` may include `--num_epochs`, `--num_steps`, `--augmentations`, `--n_val_patches`, `--n_channels_in`, and `--n_channels_out`. |
| `careamics/train` | `CAREAMICS_TRAIN` | `process_medium` | `[ val(meta), path(careamics_config), path(train_data), path(train_target), path(val_data), path(val_target) ]` | `model`: `[ val(meta), path("checkpoints/*/*last.ckpt") ]`; `versions`: `versions.yml` | Trains from an existing CAREamics configuration. `train_target`, `val_data`, and `val_target` are optional for algorithms that do not need them; use `[]` for missing paths. |

All modules support conda environments and CAREamics CPU/GPU containers. Set
`task.ext.use_gpu = true` to select the GPU container in containerized profiles. GPU is recommended.

## Example pipeline

The example pipeline is in [`example_pipeline/main.nf`](example_pipeline/main.nf).
It demonstrates training and prediction with the simple N2V, N2N, and CARE
subworkflows.

Training, validation, input, and target values can be either a file path or a
directory path. If a directory is provided, CAREamics will use the valid files in
that directory. Prediction inputs are provided with a CSV file containing a
`data_path` column. Each row becomes a separate prediction process. An optional
`id` column can be used for sample names.

### Profile options:

- Containers/Environments: `conda`|`singularity`|`docker`
- Available hardware (ignored for `conda`): `gpu`|`cpu`
- Use the `local` profile to reduce the required memory of the label `process_medium`.

### Set-up

1. Because the pipeline is in a subdirectory it cannot be run directly from github; first clone the repo to run it locally.

    ```console
    git clone https://github.com/CAREamics/CAREamics_nextflow.git
    cd CAREamics_nextflow/example_pipeline
    ```

2. Example data for N2V is available for download through a script, we recommend using uv to run it.

   ```console
   uv run get_example_data/n2v.py -wd .
   ```

   This writes the example data under `data/` and creates
   `example_n2v_predict.csv`.

### Run with `nf-core`

The example pipeline has a `nextflow_schema.json`, so you can use the nf-core
launch wizard to create a parameter JSON file before running Nextflow:

```console
nf-core pipelines launch . \
  -p params_n2v.json \
  -o nf-params.json
```

Follow the instructions to input the required parameters, `train_data` and `prediction_csv`, and update optional parameters. This can be done either through the web UI or the terminal.

### Run with Nextflow

   ```console
   nextflow run main.nf \
     -profile local,conda \
     --train_data data/N2V_SEM/train.tif \
     --val_data data/N2V_SEM/validation.tif \
     --prediction_csv example_n2v_predict.csv \
     --outdir results \
     -params-file params_n2v.json
   ```

Use `-profile local,conda` for a local run with reduced resources for
the `process_medium` label. Swap `conda` for `mamba`, `docker`, `singularity`, or
`apptainer` depending on your environment, and use `gpu` instead of `cpu` for
running with GPU-enabled containers.
