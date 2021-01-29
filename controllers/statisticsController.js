const db = require('../models');
const sequelize = db.sequelize;

exports.getGoodStatistics = async (req, res) => {
  res.json((await sequelize.query('SELECT * FROM "goods_statistics"'))[0]);
};

exports.getCategoryStatistics = async (req, res) => {
  res.json((await sequelize.query('SELECT * FROM "category_statistics"'))[0]);
};