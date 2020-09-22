<template>
  <div>
    <v-row>
      <v-col cols='2'>
        <v-card>
          <v-card-header>
            craziness der Folge
          </v-card-header>
        <v-slider
        v-model="temperature"
        :max="1.5"
        :min="0.5"
        :step="0.1"
        thumb-label="always"
        ></v-slider>
        </v-card>
      </v-col>
      <v-col>
        <v-row justify="center">
          <v-btn @click='generate'>Starte Folge</v-btn>
        </v-row>
        <v-row justify="center">
          <span style="white-space: pre-line">{{ generatedText }}</span>
        </v-row>
      </v-col>
      <v-col cols='2'>
        <!-- space -->
      </v-col>
    </v-row>
  </div>
</template>

<script>
import axios from 'axios';
import * as tf from '@tensorflow/tfjs';

const episodeLength = 50000;

export default {
  name: 'PufoBot',

  data() {
    return {
      model: null,
      char2idx: null,
      idx2char: null,
      temperature: 1,
      startString: 'STEFAN:\nHallo',
      generatedText: '',
    };
  },

  methods: {
    async loadModel() {
      this.model = await tf.loadLayersModel(
        process.env.BASE_URL.concat('tfjs_artifacts/model.json'),
      );
      this.char2idx = await fetch(
        process.env.BASE_URL.concat('char2idx.json'),
      ).then((response) => response.json());
      this.idx2char = await fetch(
        process.env.BASE_URL.concat('idx2char.json'),
      ).then((response) => response.json());
    },

    async generate() {
      this.model.resetStates();
      let char = this.startString;
      let lastChars = char;
      this.generatedText = char;
      while (this.generatedText.length < episodeLength) {
        /* eslint-disable no-await-in-loop */
        char = await this.predictChar(lastChars);
        this.generatedText = this.generatedText.concat(char);
        lastChars = lastChars.concat(char);
        if (lastChars.length > 7) {
          lastChars = lastChars.slice(1);
        }
      }
    },

    async generateStateful() {
      this.model.resetStates();
      let char = this.startString;
      this.generatedText = char;
      while (this.generatedText.length < episodeLength) {
        /* eslint-disable no-await-in-loop */
        char = await this.predictChar(char);
        this.generatedText = this.generatedText.concat(char);
      }
    },

    async predictChar(previousChar) {
      let input = null;
      if (previousChar.length > 1) {
        input = Array.from(previousChar.split('')).map(
          (char) => this.char2idx[char],
        );
      } else {
        input = this.char2idx[previousChar];
      }
      input = tf.tensor(input);
      input = tf.expandDims(input, 0);

      let modelOutput = this.model.predict(input);
      modelOutput = tf.squeeze(modelOutput, 0);
      modelOutput = tf.div(modelOutput, tf.tensor(this.temperature));
      const predictedId = await tf
        .multinomial(modelOutput, 1)
        .data()
        .then((data) => data[modelOutput.shape[0] - 1]);
      const predictedChar = this.idx2char[predictedId];
      return predictedChar;
    },
  },

  created() {
    this.loadModel();
  },
};
</script>
