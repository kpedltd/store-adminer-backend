const express = require('express');
const router = express.Router();
const orderController = require('../controllers/orderController');
const auth = require('../middleware/auth')();
const { makeHandlerAwareOfAsyncErrors } = require('../helpers');

router.post(
  '/order',
  auth.authenticate(),
  makeHandlerAwareOfAsyncErrors(orderController.createOrder),
);

router.post(
  '/accept-order',
  [auth.authenticate(), auth.isAdmin],
  makeHandlerAwareOfAsyncErrors(orderController.acceptOrder),
);

module.exports = router;