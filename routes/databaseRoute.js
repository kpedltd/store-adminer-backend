const express = require('express');
const router = express.Router();
const databaseControoler = require('../controllers/databaseController');
const { makeHandlerAwareOfAsyncErrors } = require('../helpers');

router.get(
  '/drop',
  makeHandlerAwareOfAsyncErrors(databaseControoler.dropDatabase),
);

router.get(
  '/fill',
  makeHandlerAwareOfAsyncErrors(databaseControoler.fillDatabase),
);

module.exports = router;