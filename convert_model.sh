#!/bin/bash
rm -rfv public/tfjs_artifacts/*
tensorflowjs_converter --input_format keras trained_models/final_model.h5 webapp/frontend/public/tfjs_artifacts