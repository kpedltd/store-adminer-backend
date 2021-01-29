const express = require('express');
const router = express.Router();
const statisticsController = require('../controllers/statisticsController');
const auth = require('../middleware/auth')();
const { makeHandlerAwareOfAsyncErrors } = require('../helpers');

router.get(
  '/good-statistics',
  [auth.authenticate(), auth.isAdmin],
  makeHandlerAwareOfAsyncErrors(statisticsController.getGoodStatistics)
);

router.get(
  '/category-statistics',
  [auth.authenticate(), auth.isAdmin],
  makeHandlerAwareOfAsyncErrors(statisticsController.getCategoryStatistics)
);

module.exports = router;