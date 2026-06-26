#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

/*
========================================================================================
    CAREamics
========================================================================================
    Example pipeline demonstrating:
    Perform image restoration on microscopy images using CAREamics (N2V, CARE, or N2N).
    
    Usage:
        nextflow run careamics_pipeline.nf \
            -profile conda|singularity|docker,gpu|cpu \
            -params-file params_n2v.json
========================================================================================
*/

// Import CAREamics subworkflows
include { IMAGE_TRAIN_PREDICT_N2V_CAREAMICS  } from "./subworkflows/careamics/image_train_predict_n2v_careamics"
include { IMAGE_TRAIN_PREDICT_N2N_CAREAMICS  } from "./subworkflows/careamics/image_train_predict_n2n_careamics"
include { IMAGE_TRAIN_PREDICT_CARE_CAREAMICS } from "./subworkflows/careamics/image_train_predict_care_careamics"


/*
========================================================================================
    MAIN WORKFLOW
========================================================================================
*/

workflow {
    // Train model first
    log.info("Training ${params.algorithm} algorithm.")

    // Meta
    def meta = [id: params.experiment_name]

    // Config channel
    ch_config = channel.of(
        [
            meta,
            params.experiment_name,
            params.data_type,
            params.axes,
            params.patch_size,
            params.batch_size,
        ]
    )

    // Prediction data channel
    ch_prediction_data = channel.fromPath(params.prediction_csv, checkIfExists: true)
        .splitCsv(header: true)
        .map { row ->
            if (!row.data_path) {
                error("Prediction CSV must contain an 'data_path' column")
            }
            def predictionPath = file(row.data_path, checkIfExists: true)
            def pred_meta = [id: row.id ?: predictionPath.baseName]
            return [pred_meta, predictionPath]
        }

    // Self-supervised algorithms
    if (params.algorithm == 'n2v') {
        ch_training = channel.of([meta, file(params.train_data), file(params.val_data) ?: []])
        IMAGE_TRAIN_PREDICT_N2V_CAREAMICS(ch_config, ch_training, ch_prediction_data)
    }
    else if ((params.algorithm == 'care') || (params.algorithm == 'n2n')) {
        if (!params.train_target) {
            error("Please provide --train_target for algorithm: ${params.algorithm}")
        }
        if (params.val_data && !params.val_target) {
            error(
                "Please provide both --val_data and --val_target for algorithm: ${params.algorithm}, or neither."
            )
        }
        ch_training = channel.of(
            [
                meta,
                file(params.train_data),
                file(params.train_target),
                file(params.val_data) ?: [],
                file(params.val_target) ?: [],
            ]
        )
        if (params.algorithm == 'care') {
            IMAGE_TRAIN_PREDICT_CARE_CAREAMICS(ch_config, ch_training, ch_prediction_data)
        }
        else {
            // n2n
            IMAGE_TRAIN_PREDICT_N2N_CAREAMICS(ch_config, ch_training, ch_prediction_data)
        }
    }
    else {
        error("Unknown algorithm: ${params.algorithm}. Use 'n2v', 'care', or 'n2n'")
    }
}
