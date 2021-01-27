const db = require('../models');
const User = db.user;
const RefreshToken = db.refreshToken;
const Role = require('../models/role');
const Op = db.Sequelize.Op;

exports.profile = async (req, res) => {
  res.json(await User.findOne({
    where: { id: req.user.id },
    attributes: {
      exclude: [
        'passwordHash',
        'udatedAt'
      ]
    }
  }));
};

exports.users = async (req, res) => {
  res.json(await User.findAll({
    attributes: {
      exclude: [
        'passwordHash',
        'updatedAt'
      ]
    },
    order: [
      'id'
    ]
  }));
};

exports.refreshTokens = async (req, res) => {
  const userId = req.query.userId;
  if (req.user.id != userId && req.user.role !== Role.Admin) {
    throw createError(403, 'You are not have privileges');
  }

  res.json(await RefreshToken.findAll({
    attributes: [
      'token',
      'exp',
      'createdByIp'
    ],
    where: {
      userId: userId,
      revoked: {
        [Op.is]: null,
      },
      exp: {
        [Op.gte]: new Date()
      }
    }
  }));
};

exports.blockUser = async (req, res) => {
  const user = await User.findOne({ where: { id: req.query.userId } });
  if (user === undefined) {
    throw createError(404, 'User not found.');
  }
  user.isBlocked = true;
  await user.save();

  console.log('User "' + user.login + '" successfuly blocked.');
  res.json({ msg: 'User "' + user.login + '" successfuly blocked.' });
};

exports.unblockUser = async (req, res) => {
  const user = await User.findOne({ where: { id: req.query.userId } });
  if (user === undefined) {
    throw createError(404, 'User not found.');
  }
  user.isBlocked = false;
  await user.save();

  console.log('User "' + user.login + '" successfuly unblocked.');
  res.json({ msg: 'User "' + user.login + '" successfuly unblocked.' });
};