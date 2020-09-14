<template>
  <div>
    <v-row>
      <v-col cols='2'>
        <v-slider
        v-model="temperature"
        :max="2"
        :min="0.1"
        :step="0.1"
        thumb-label="always"
        ></v-slider>
      </v-col>
      <v-col>
        <v-row  justify="center">
          <h1>Pufo BOT</h1>
        </v-row>
        <v-row justify="center">
          <v-btn @click='generateStateful'>Starte Folge</v-btn>
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

export default {
  name: 'PufoBot',

  data() {
    return {
      model: null,
      char2idx: null,
      idx2char: null,
      temperature: 1,
      startString: 'STEFAN:',
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
      let char = this.startString;
      let lastChars = char;
      this.generatedText = char;
      while (this.generatedText.length < 2000) {
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
      let char = this.startString;
      this.generatedText = char;
      while (this.generatedText.length < 2000) {
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
