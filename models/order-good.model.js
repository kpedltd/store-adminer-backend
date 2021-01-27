module.exports = (sequelize, Sequelize) => {
  const OrderGood = sequelize.define('order_good', {
    orderId: {
      type: Sequelize.INTEGER,
      allowNull: false,
      primaryKey: true,
    },
    goodId: {
      type: Sequelize.INTEGER,
      allowNull: false,
      primaryKey: true,
    },
    amount: {
      type: Sequelize.INTEGER,
      allowNull: false,
    },
    priceId: {
      type: Sequelize.INTEGER,
      allowNull: false,
    },
  });

  OrderGood.associate = function (db) {
    db.order.hasMany(OrderGood, { foreignKey: 'orderId' });
    db.good.hasMany(OrderGood, { foreignKey: 'goodId' });
    db.price.hasMany(OrderGood, { foreignKey: 'priceId' });
  };

  return OrderGood;
};
