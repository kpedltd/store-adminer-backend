const Status = require('./status');

module.exports = (sequelize, Sequelize) => {
  const Order = sequelize.define('order', {
    userId: {
      type: Sequelize.INTEGER,
      allowNull: false,
    },
    status: {
      type: Sequelize.STRING,
      allowNull: false,
      defaultValue: Status.PROCESSING,
    },
  });

  Order.associate = function (db) {
    db.user.hasMany(Order, { foreignKey: 'userId' });
    Order.belongsTo(db.user, { foreignKey: 'userId' });
  };

  return Order;
};