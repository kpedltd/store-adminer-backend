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

router.get(
  '/order',
  [auth.authenticate(), auth.isAdmin],
  makeHandlerAwareOfAsyncErrors(orderController.getOrders),
);

router.post(
  '/accept-order',
  [auth.authenticate(), auth.isAdmin],
  makeHandlerAwareOfAsyncErrors(orderController.acceptOrder),
);

router.post(
  '/reject-order',
  [auth.authenticate(), auth.isAdmin],
  makeHandlerAwareOfAsyncErrors(orderController.rejectOrder),
);

router.post(
  '/send-order',
  [auth.authenticate(), auth.isAdmin],
  makeHandlerAwareOfAsyncErrors(orderController.sendOrder),
);

router.post(
  '/order-arrived',
  auth.authenticate(),
  makeHandlerAwareOfAsyncErrors(orderController.markOrderArrived),
);

router.post(
  '/order-gone',
  [auth.authenticate(), auth.isAdmin],
  makeHandlerAwareOfAsyncErrors(orderController.markOrderGone),
);

module.exports = router;