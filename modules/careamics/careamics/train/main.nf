process CAREAMICS_TRAIN {
    tag "${meta.id ?: task.process}"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container {
        def is_singularity = workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container

        if (is_singularity) {
            return 'oras://ghcr.io/careamics/careamics-sif:0.3.5-cuda11.8'
        }
        else {
            return 'ghcr.io/careamics/careamics:0.3.5-cuda11.8'
        }
    }

    input:
    tuple val(meta), path(careamics_config), path(train_data), path(train_target), path(val_data), path(val_target)

    output:
    tuple val(meta), path("checkpoints/*/*.ckpt", arity: '1..*'), path("checkpoints/*/checkpoint_record.json", arity: '1'), emit: model
    tuple val(meta), path("csv_logs/*/version_*/metrics.csv", arity: '1'), emit: metrics
    tuple val("${task.process}"), val('careamics'), eval('python -c "import careamics; print(careamics.__version__)"'), emit: versions_careamics, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    if (!val_data && val_target) {
        error "Provide val_data when val_target is provided."
    }
    def train_target_args = train_target ? "--train_target ${train_target}" : ''
    def val_args = val_data ? "--val_data ${val_data}" : ''
    def val_target_args = val_target ? "--val_target ${val_target}" : ''
    """
    train.py \\
        --output_path . \\
        --config ${careamics_config} \\
        --train_data ${train_data} \\
        ${train_target_args} \\
        ${val_args} \\
        ${val_target_args} \\
        ${args}

    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p "checkpoints/${prefix}"
    touch "checkpoints/${prefix}/best.ckpt"
    touch "checkpoints/${prefix}/last.ckpt"
    cat <<-END_RECORD > "checkpoints/${prefix}/checkpoint_record.json"
    {
        "last": "last.ckpt",
        "best": "best.ckpt",
        "monitor": "val_loss",
        "mode": "min",
        "best_k": [{"name": "best.ckpt", "score": 0.1}],
        "checkpoints": ["best.ckpt", "last.ckpt"],
        "selected": "last.ckpt"
    }
    END_RECORD

    mkdir -p "csv_logs/${prefix}/version_0"
    cat <<-END_METRICS > "csv_logs/${prefix}/version_0/metrics.csv"
    epoch,step,train_loss,val_loss
    0,0,0.2,0.1
    END_METRICS
    """
}
