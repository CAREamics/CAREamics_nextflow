include { CAREAMICS_TRAIN   } from '../../../modules/careamics/careamics/train/main'
include { CAREAMICS_PREDICT } from '../../../modules/careamics/careamics/predict/main'

workflow IMAGE_TRAIN_PREDICT_CAREAMICS {
    take:
    ch_train // [ val(meta), path(careamics_config), path(train_data), path(train_target), path(val_data), path(val_target) ]
    ch_predict // [ val(meta), path(data) ]

    main:
    CAREAMICS_TRAIN(ch_train)

    // expose all trained checkpoints without the checkpoint record
    ch_checkpoints = CAREAMICS_TRAIN.out.model
        .map { model_meta, checkpoints, checkpoint_record ->
            [model_meta, checkpoints]
        }

    // extract selected checkpoint from checkpoints record
    ch_model = CAREAMICS_TRAIN.out.model
        .map { model_meta, checkpoints, checkpoint_record ->
            def record = new groovy.json.JsonSlurper().parseText(checkpoint_record.text)
            def model = checkpoints.find { checkpoint -> checkpoint.name == record.selected }
            if (!model) {
                error("Cannot locate selected checkpoint '${record.selected}' in checkpoints emitted by CAREAMICS_TRAIN")
            }
            [model_meta, model]
        }

    ch_predict_input = ch_predict
        .combine(ch_model)
        .map { predict_meta, data, model_meta, model ->
            def meta = predict_meta + [model_id: model_meta.id]
            [meta, data, model]
        }

    CAREAMICS_PREDICT(ch_predict_input)

    emit:
    checkpoints = ch_checkpoints // [ val(meta), path(checkpoints) ]
    metrics     = CAREAMICS_TRAIN.out.metrics // [ val(meta), path(metrics.csv) ]
    model       = ch_model // [ val(meta), path(model) ]
    predictions = CAREAMICS_PREDICT.out.predictions // [ val(meta), path(predictions) ]
    versions    = CAREAMICS_TRAIN.out.versions.mix(CAREAMICS_PREDICT.out.versions) // [ path(versions.yml) ]
}
