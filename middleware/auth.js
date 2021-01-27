const passport = require('passport');
const passportJWT = require('passport-jwt');
const config = require('../config.js');
const Role = require('../models/role');
const db = require('../models');
const User = db.user;

let ExtractJwt = passportJWT.ExtractJwt;
let Strategy = passportJWT.Strategy;
let params = {
  secretOrKey: config.jwtSecret,
  jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken()
};

const getUser = async obj => {
  return await User.findOne({
    where: obj,
  });
};

const isAdmin = (req, res, next) => {
  if (req.user && req.user.role === Role.Admin) {
    next();
    return;
  }

  res.status(403).json({ msg: 'You are not have privileges' });
};

module.exports = function () {
  var strategy = new Strategy(params, function (payload, done) {
    getUser({ id: payload.id })
      .then(user => {
        if (Date.now() >= payload.exp) {
          return done(new Error('TokenExpired'), null);
        }
        if (user.isBlocked) {
          return done(new Error('You are restricted'), null);
        }
        done(null, user)
      })
      .catch(err => done(err, null));
  });
  passport.use(strategy);
  return {
    initialize: function () {
      return passport.initialize();
    },
    authenticate: function () {
      return passport.authenticate('jwt', config.jwtSession);
    },
    isAdmin: isAdmin,
  };
};