const config = require('../config.js');
const createError = require('http-errors');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const Role = require('../models/role');
const db = require('../models');
const User = db.user;
const RefreshToken = db.refreshToken;

const ACCESS_TOKEN_LIFESPAN = 1000 * 60 * 60; // 1 hour
const REFRESH_TOKEN_LIFESPAN = 1000 * 60 * 60 * 24 * 7; // 7 days

const createUser = async ({ login, lastname, firstname, password }) => {
  const role = Role.User;
  return await User.create({ login, lastname, firstname, password, role });
};

const generateJwtToken = (user) => {
  const exp = Date.now() + ACCESS_TOKEN_LIFESPAN;
  let payload = {
    id: user.id,
    role: user.role,
    exp: exp,
  }
  return {
    accessToken: jwt.sign(payload, config.jwtSecret),
    exp: exp
  };
};

const getRefreshToken = async obj => {
  return await RefreshToken.findOne({
    where: obj,
  });
};

const generateRefreshToken = async (user, ipAdress) => {
  return await RefreshToken.create({
    userId: user.id,
    token: randomTokenString(),
    exp: Date.now() + REFRESH_TOKEN_LIFESPAN,
    createdByIp: ipAdress,
  });
};

const randomTokenString = () => {
  return crypto.randomBytes(40).toString('hex');
};

const setTokenCookie = (res, token) => {
  let cookieOptions = {
    httpOnly: true,
    expires: new Date(Date.now() + REFRESH_TOKEN_LIFESPAN),
  };
  res.cookie('refreshToken', token, cookieOptions);
};

exports.login = async (req, res) => {
  const { login, password } = req.body;
  const { isAdmin } = req.query;
  if (!login || !password) {
    throw createError.BadRequest();
  }

  const ipAdress = req.ip;
  if (login && password) {
    let user = await User.findOne({ where: { login } });
    if (!user) {
      throw createError(401, 'User Not Found');
    }
    if (user.isBlocked) {
      throw createError(403, 'You are restricted');
    }

    if (isAdmin && isAdmin === 'true' && user.role !== Role.Admin) {
      throw createError(403, 'You are not have privileges');
    }

    if (user.comparePassword(password)) {
      user.lastLogin = Date.now();
      user.lastLoginIp = ipAdress;
      await user.save();

      let refreshToken = await generateRefreshToken(user, ipAdress);
      let jwtToken = generateJwtToken(user);

      console.log('User "' + login + '" logged in.')
      console.log({
        role: user.role,
        accessToken: jwtToken.accessToken,
        refreshToken: refreshToken.token,
      });
      setTokenCookie(res, refreshToken.token);
      jwtToken.role = user.role;
      res.json(jwtToken);
    } else {
      throw createError(401, 'Wrong Password');
    }
  }

};

exports.join = async (req, res) => {
  const { login, lastname, firstname, password } = req.body;
  if (!login || !lastname || !firstname || !password) {
    throw createError.BadRequest();
  }
  const user = await createUser({ login, lastname, firstname, password })

  console.log('User "' + user.login + '" successfully created.');
  return res.json({ msg: 'User created successfully' });

};

exports.refreshToken = async function (req, res) {
  const token = req.cookies.refreshToken;
  if (!token) {
    throw createError.BadRequest();
  }
  const ipAdress = req.ip;

  const refreshToken = await getRefreshToken({ token });
  if (!refreshToken) {
    throw createError(400, 'Invalid Refresh Token');
  }
  if (!refreshToken.isActive()) {
    throw createError(401, 'Refresh token is expired or revoked');
  }
  const { userId } = refreshToken;
  const user = await User.findOne({ where: { id: userId } });
  if (!user) {
    throw createError(401, 'User Not Found');
  }
  if (user.isBlocked) {
    throw createError(403, 'You are restricted');
  }

  const newRefreshToken = await generateRefreshToken(user, ipAdress);
  refreshToken.revoked = Date.now();
  refreshToken.revokedByIp = ipAdress;
  refreshToken.replacedByToken = newRefreshToken.token;
  await refreshToken.save();

  const jwtToken = generateJwtToken(user);

  console.log('User "' + user.login + '" refreshed token.');
  console.log({
    oldRefreshToken: token,
    newRefreshToken: newRefreshToken.token,
    accessToken: jwtToken.accessToken,
  });

  setTokenCookie(res, newRefreshToken.token);
  res.json(jwtToken);

};

exports.revokeToken = async (req, res) => {
  const token = req.body.token || req.cookies.refreshToken;
  console.log(token);
  if (!token) {
    throw createError.BadRequest();
  }

  const ipAdress = req.ip;

  const refreshToken = await getRefreshToken({ token });
  if (!refreshToken) {
    throw createError(400, 'Invalid Refresh Token');
  }

  if (!req.user.ownsRefreshToken(refreshToken) && req.user.role !== Role.Admin) {
    throw createError(403, 'You are not have privileges');
  }

  refreshToken.revoked = Date.now();
  refreshToken.revokedByIp = ipAdress;
  await refreshToken.save();

  console.log('Refresh token of user "' + req.user.login + '" has been revoked.')
  console.log({
    revokedRefreshToken: refreshToken.token,
  })

  res.json({ msg: 'Token revoked' });

};