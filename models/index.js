const config = require('../config');

const Sequelize = require('sequelize');
const sequelize = new Sequelize(
  config.db,
  config.user,
  config.password,
  {
    host: config.host,
    dialect: config.dialect,
    logging: false,
  }
);

const db = {}

db.user = require('./user.model')(sequelize, Sequelize);
db.refreshToken = require('./refreshToken.model')(sequelize, Sequelize);
db.category = require('./category.model')(sequelize, Sequelize);
db.good = require('./good.model')(sequelize, Sequelize);
db.price = require('./price.model')(sequelize, Sequelize);
db.order = require('./order.model')(sequelize, Sequelize);
db.orderGood = require('./order-good.model')(sequelize, Sequelize);

db.refreshToken.associate(db);
db.good.associate(db);
db.price.associate(db);
db.order.associate(db);
db.orderGood.associate(db);

db.Sequelize = Sequelize;
db.sequelize = sequelize;

module.exports = db;