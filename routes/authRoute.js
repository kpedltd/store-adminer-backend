const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const auth = require('../middleware/auth')();
const { makeHandlerAwareOfAsyncErrors } = require('../helpers');

router.post(
  '/join',
  makeHandlerAwareOfAsyncErrors(authController.join)
);

router.post(
  '/login',
  makeHandlerAwareOfAsyncErrors(authController.login)
);

router.post(
  '/refresh-token',
  makeHandlerAwareOfAsyncErrors(authController.refreshToken)
);

router.post(
  '/revoke-token',
  auth.authenticate(),
  makeHandlerAwareOfAsyncErrors(authController.revokeToken)
);

module.exports = router;