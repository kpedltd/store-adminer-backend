const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const auth = require('../middleware/auth')();
const { makeHandlerAwareOfAsyncErrors } = require('../helpers');

router.get(
  '/profile',
  auth.authenticate(),
  makeHandlerAwareOfAsyncErrors(userController.profile)
);

router.get(
  '/users',
  [auth.authenticate(), auth.isAdmin],
  makeHandlerAwareOfAsyncErrors(userController.users)
);

router.get(
  '/tokens',
  auth.authenticate(),
  makeHandlerAwareOfAsyncErrors(userController.refreshTokens)
);

router.post(
  '/block-user',
  [auth.authenticate(), auth.isAdmin],
  makeHandlerAwareOfAsyncErrors(userController.blockUser)
);

router.post(
  '/unblock-user',
  [auth.authenticate(), auth.isAdmin],
  makeHandlerAwareOfAsyncErrors(userController.unblockUser)
);

module.exports = router;