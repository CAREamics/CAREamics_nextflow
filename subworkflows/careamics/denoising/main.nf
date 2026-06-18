include { CAREAMICS_TRAIN_N2V  } from '../../../modules/careamics/train/n2v/main'
include { CAREAMICS_TRAIN_CARE } from '../../../modules/careamics/train/care/main'
include { CAREAMICS_TRAIN_N2N  } from '../../../modules/careamics/train/n2n/main'
include { CAREAMICS_PREDICT    } from '../../../modules/careamics/predict/main'

workflow CAREAMICS_DENOISING {

    take:
    // Channel: [ val(meta), path(train_data), path(target_data), path(val_data), path(val_target) ]
    //   meta map with at minimum: id, algorithm (n2v/care/n2n/structn2v)
    //   train_data: path to training images
    //   target_data: path to target images (optional, null for n2v/structn2v)
    //   val_data: optional path to validation images
    //   val_target: optional path to validation target images
    ch_training_input
    // Channel: [ val(meta), path(test_data) ]
    //   meta map with at minimum: id
    //   test_data: path to test images for prediction
    ch_test_data

    main:
    def ch_versions = channel.empty()
    def ch_models   = channel.empty()
    def ch_configs  = channel.empty()

    // Branch training data by algorithm
    ch_training_input
        .branch { meta, train, target, val, val_target ->
            n2v: meta.algorithm == 'n2v' || meta.algorithm == 'structn2v'
                return [meta, train, val ?: []]
            care: meta.algorithm == 'care'
                return [meta, train, target, val ?: [], val_target ?: []]
            n2n: meta.algorithm == 'n2n'
                return [meta, train, target, val ?: [], val_target ?: []]
        }
        .set { ch_branched }

    // Train N2V models
    CAREAMICS_TRAIN_N2V(ch_branched.n2v)
    ch_versions = ch_versions.mix(CAREAMICS_TRAIN_N2V.out.versions)
    ch_models   = ch_models.mix(CAREAMICS_TRAIN_N2V.out.model)
    ch_configs  = ch_configs.mix(CAREAMICS_TRAIN_N2V.out.config)

    // Train CARE models
    CAREAMICS_TRAIN_CARE(ch_branched.care)
    ch_versions = ch_versions.mix(CAREAMICS_TRAIN_CARE.out.versions)
    ch_models   = ch_models.mix(CAREAMICS_TRAIN_CARE.out.model)
    ch_configs  = ch_configs.mix(CAREAMICS_TRAIN_CARE.out.config)

    // Train N2N models
    CAREAMICS_TRAIN_N2N(ch_branched.n2n)
    ch_versions = ch_versions.mix(CAREAMICS_TRAIN_N2N.out.versions)
    ch_models   = ch_models.mix(CAREAMICS_TRAIN_N2N.out.model)
    ch_configs  = ch_configs.mix(CAREAMICS_TRAIN_N2N.out.config)

    // Combine test data with trained models for prediction
    // Cross all test data with all models (or can be joined by meta.id if needed)
    ch_test_data
        .combine(ch_models)
        .map { test_meta, test_path, model_meta, model_path ->
            // Merge meta maps, keeping test meta as base
            def merged_meta = test_meta + [model_id: model_meta.id]
            return [merged_meta, test_path, model_path]
        }
        .set { ch_predict_input }

    // Run prediction
    CAREAMICS_PREDICT(ch_predict_input)
    ch_versions = ch_versions.mix(CAREAMICS_PREDICT.out.versions)

    emit:
    config      = ch_configs      // Channel: [ val(meta), path(config.yaml) ]
    model       = ch_models       // Channel: [ val(meta), path(checkpoint) ]
    predictions = CAREAMICS_PREDICT.out.predictions // Channel: [ val(meta), path(predictions/*) ]
    versions    = ch_versions     // Channel: [ val(process), val(tool), val(version) ]
}
