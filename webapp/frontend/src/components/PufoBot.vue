<template>
  <div>
    <h1>Pufo BOT</h1>
    <button @click="generate">Starte Folge</button>
    <span>{{ generatedText }}</span>
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
      this.model = await tf.loadLayersModel(process.env.BASE_URL.concat('tfjs_artifacts/model.json'));
      this.char2idx = await fetch(process.env.BASE_URL.concat('char2idx.json')).then((response) => response.json());
      this.idx2char = await fetch(process.env.BASE_URL.concat('idx2char.json')).then((response) => response.json());
    },

    async generate() {
      let char = this.startString;
      let lastChars = char;
      this.generatedText = char;
      while (this.generatedText.length < 1000) {
        /* eslint-disable no-await-in-loop */
        char = await this.predictChar(lastChars);
        this.generatedText = this.generatedText.concat(char);
        lastChars = lastChars.concat(char);
        if (lastChars.length > 4) {
          lastChars = lastChars.slice(1);
        }
      }
    },

    async predictChar(previousChar) {
      let input = null;
      if (previousChar.length > 1) {
        input = Array.from(previousChar.split('')).map((char) => this.char2idx[char]);
      } else {
        input = this.char2idx[previousChar];
      }
      input = tf.tensor(input);
      input = tf.expandDims(input, 0);

      let modelOutput = this.model.predict(input);
      modelOutput = tf.squeeze(modelOutput, 0);
      modelOutput = tf.div(modelOutput, tf.tensor(this.temperature));
      const predictedId = await tf.multinomial(modelOutput, 1).data()
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
