const express = require('express');
const router = express.Router();
const goodController = require('../controllers/goodController');
const auth = require('../middleware/auth')();
const { makeHandlerAwareOfAsyncErrors } = require('../helpers');

router.post(
  '/category',
  [auth.authenticate(), auth.isAdmin],
  makeHandlerAwareOfAsyncErrors(goodController.createCategory)
);

router.get(
  '/category',
  auth.authenticate(),
  makeHandlerAwareOfAsyncErrors(goodController.getCategory)
);

router.post(
  '/remove-categories',
  [auth.authenticate(), auth.isAdmin],
  makeHandlerAwareOfAsyncErrors(goodController.removeCategories)
);

router.post(
  '/update-category',
  [auth.authenticate(), auth.isAdmin],
  makeHandlerAwareOfAsyncErrors(goodController.updateCategory)
);

router.post(
  '/good',
  [auth.authenticate(), auth.isAdmin],
  makeHandlerAwareOfAsyncErrors(goodController.createGood)
);

router.get(
  '/good',
  auth.authenticate(),
  makeHandlerAwareOfAsyncErrors(goodController.getGood)
);

router.post(
  '/remove-goods',
  [auth.authenticate(), auth.isAdmin],
  makeHandlerAwareOfAsyncErrors(goodController.removeGoods)
);

router.post(
  '/update-good',
  [auth.authenticate(), auth.isAdmin],
  makeHandlerAwareOfAsyncErrors(goodController.updateGood)
);

router.post(
  '/price-history',
  [auth.authenticate(), auth.isAdmin],
  makeHandlerAwareOfAsyncErrors(goodController.getPriceHistory)
);

module.exports = router;