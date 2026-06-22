def zarr_group_uri(data_path, inner_zarr_path) {
    inner_zarr_path ? "file://${data_path}/${inner_zarr_path}" : data_path
}

process CAREAMICS_TRAIN_CARE {
    tag "${meta.id}"
    label 'process_gpu_medium'

    conda "${moduleDir}/environment.yml"
    container {
        def use_gpu = task.ext.use_gpu ?: false
        def is_singularity = workflow.containerEngine in ['singularity', 'apptainer']

        if (use_gpu && is_singularity) {
            return 'oras://ghcr.io/careamics/careamics-gpu-sif:0.2.0'
        }
        else if (!use_gpu && is_singularity) {
            return 'oras://ghcr.io/careamics/careamics-cpu-sif:0.2.0'
        }
        else if (use_gpu && !is_singularity) {
            return 'ghcr.io/careamics/careamics-gpu:0.2.0'
        }
        else {
            return 'ghcr.io/careamics/careamics-cpu:0.2.0'
        }
    }

    input:
    tuple val(meta), path(train_data), val(train_inner_zarr_path), path(train_target), val(train_target_inner_zarr_path), path(val_data), val(val_inner_zarr_path), path(val_target), val(val_target_inner_zarr_path)

    output:
    tuple val(meta), path("*.yaml"), emit: config
    // TODO: get real checkpoint name from CAREamist.get_checkpoints
    tuple val(meta), path("checkpoints/*/*last.ckpt"), emit: model
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    if ((val_data && !val_target) || (!val_data && val_target)) {
        error "Both val_data and val_target must be provided for ${task.process}, or neither."
    }
    if (val_inner_zarr_path?.toString() && !val_data) {
        error "val_inner_zarr_path requires val_data for ${task.process}."
    }
    if (val_target_inner_zarr_path?.toString() && !val_target) {
        error "val_target_inner_zarr_path requires val_target for ${task.process}."
    }
    def train_data_arg = zarr_group_uri(train_data, train_inner_zarr_path)
    def train_target_arg = zarr_group_uri(train_target, train_target_inner_zarr_path)
    def val_data_arg = val_data ? zarr_group_uri(val_data, val_inner_zarr_path) : null
    def val_target_arg = val_target ? zarr_group_uri(val_target, val_target_inner_zarr_path) : null
    def val_args = val_data ? "--val_data \"${val_data_arg}\" --val_target \"${val_target_arg}\"" : ''
    """
    train_care.py \\
        --train_data "${train_data_arg}" \\
        --train_target "${train_target_arg}" \\
        ${val_args} \\
        --output_path . \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        careamics: \$(python -c "import careamics; print(careamics.__version__)")
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch "${prefix}_config.yaml"
    mkdir -p checkpoints/stub
    touch checkpoints/stub/last.ckpt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        careamics: stub
    END_VERSIONS
    """
}
